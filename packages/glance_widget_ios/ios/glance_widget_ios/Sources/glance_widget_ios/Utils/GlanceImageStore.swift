import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Turns an image widget's declared source into a small file in the App Group
/// container, ahead of the widget ever being drawn.
///
/// Fetching and downsampling happen here, at update time, rather than in the
/// widget extension. An extension runs under a much tighter memory budget than
/// the app and is killed rather than throttled when it overruns, and WidgetKit
/// will not wait for a network round trip during a timeline reload.
public enum GlanceImageStore {
    public enum StoreResult: Equatable {
        /// The picture is at this path, already downsampled.
        case stored(path: String)

        /// There was no picture to store.
        case empty

        /// The picture could not be produced, and why.
        case failed(reason: String)
    }

    private static let directoryName = "GlanceWidgetImages"
    private static let requestTimeout: TimeInterval = 15

    /// Resolves the picture for [widgetId] and writes it into [containerURL].
    public static func store(
        widgetId: String,
        imageBase64: String?,
        imageUrl: String?,
        containerURL: URL,
        session: URLSession = .shared,
        completion: @escaping (StoreResult) -> Void
    ) {
        switch GlanceImageResolver.source(imageBase64: imageBase64, imageUrl: imageUrl) {
        case .none:
            completion(.empty)

        case let .invalid(reason):
            completion(.failed(reason: reason))

        case let .inline(base64):
            guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else {
                completion(.failed(reason: "imageBase64 is not valid base64"))
                return
            }
            completion(downsampleAndWrite(data: data, widgetId: widgetId, containerURL: containerURL))

        case let .remote(url):
            download(url: url, session: session) { result in
                switch result {
                case let .failure(reason):
                    completion(.failed(reason: reason))
                case let .success(data):
                    completion(downsampleAndWrite(data: data, widgetId: widgetId, containerURL: containerURL))
                }
            }
        }
    }

    /// Drops the cached picture for [widgetId], if any.
    public static func evict(widgetId: String, containerURL: URL) {
        try? FileManager.default.removeItem(at: fileURL(widgetId: widgetId, containerURL: containerURL))
    }

    public static func fileURL(widgetId: String, containerURL: URL) -> URL {
        // Widget ids come from the app and may contain anything, so they are not
        // used as path components directly.
        let name = String(format: "%08x", UInt32(bitPattern: Int32(truncatingIfNeeded: widgetId.hashValue)))
        return containerURL
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent("\(name).png")
    }

    // MARK: - Downsampling

    /// Decodes at a reduced size and writes the result.
    ///
    /// `CGImageSourceCreateThumbnailAtIndex` never materialises the full-size
    /// bitmap, which is the point: a widget extension cannot afford to hold a
    /// 4000x3000 picture even briefly.
    private static func downsampleAndWrite(
        data: Data,
        widgetId: String,
        containerURL: URL
    ) -> StoreResult {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return .failed(reason: "image data could not be read")
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: GlanceImageResolver.maxEdgePixels,
        ]

        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return .failed(reason: "image data could not be decoded")
        }

        let destinationURL = fileURL(widgetId: widgetId, containerURL: containerURL)
        do {
            try FileManager.default.createDirectory(
                at: destinationURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            return .failed(reason: "could not create the widget image directory: \(error.localizedDescription)")
        }

        // Written beside the target and moved into place, so the extension never
        // reads a half-written file.
        let temporaryURL = destinationURL.appendingPathExtension("tmp")
        guard let destination = CGImageDestinationCreateWithURL(
            temporaryURL as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return .failed(reason: "could not open the widget image for writing")
        }

        CGImageDestinationAddImage(destination, thumbnail, nil)
        guard CGImageDestinationFinalize(destination) else {
            try? FileManager.default.removeItem(at: temporaryURL)
            return .failed(reason: "could not encode the widget image")
        }

        do {
            _ = try FileManager.default.replaceItemAt(destinationURL, withItemAt: temporaryURL)
        } catch {
            try? FileManager.default.removeItem(at: temporaryURL)
            return .failed(reason: "could not move the decoded image into place: \(error.localizedDescription)")
        }

        return .stored(path: destinationURL.path)
    }

    // MARK: - Fetching

    private enum Download {
        case success(Data)
        case failure(String)
    }

    /// Fetches [url], following redirects by hand.
    ///
    /// `URLSession` would follow them itself, applying the scheme check to the
    /// first hop only, so a permitted `https://` address could hand the fetch on
    /// to something the check never saw. Each hop is re-validated here instead,
    /// and the chain is bounded.
    ///
    /// Note on reachable addresses: private and loopback ranges are deliberately
    /// NOT blocked. The app can already make this request itself, so refusing
    /// them would buy little and would break serving widget images from a LAN
    /// host or a local dev server. Apps that put third-party URLs into
    /// `imageUrl` should validate them as they would any other URL they fetch.
    private static func download(
        url: URL,
        session: URLSession,
        redirectsLeft: Int = GlanceImageResolver.maxRedirects,
        completion: @escaping (Download) -> Void
    ) {
        var request = URLRequest(url: url)
        request.timeoutInterval = requestTimeout
        request.httpMethod = "GET"

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error as NSError?, error.code == NSURLErrorCancelled {
                completion(.failure("fetching imageUrl was cancelled"))
                return
            }
            if let error = error {
                completion(.failure("could not fetch imageUrl: \(error.localizedDescription)"))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure("imageUrl did not return an HTTP response"))
                return
            }

            if (300...399).contains(http.statusCode) {
                guard redirectsLeft > 0 else {
                    completion(.failure("imageUrl exceeded \(GlanceImageResolver.maxRedirects) redirects"))
                    return
                }
                guard let location = http.value(forHTTPHeaderField: "Location") else {
                    completion(.failure("imageUrl redirected with no Location header"))
                    return
                }
                // Resolved against the current URL, since Location may be
                // relative, then put back through the same scheme check.
                guard let next = URL(string: location, relativeTo: url)?.absoluteURL,
                      case let .remote(checked) = GlanceImageResolver.source(
                          imageBase64: nil,
                          imageUrl: next.absoluteString
                      ) else {
                    completion(.failure("imageUrl redirect refused: '\(location)'"))
                    return
                }
                download(
                    url: checked,
                    session: session,
                    redirectsLeft: redirectsLeft - 1,
                    completion: completion
                )
                return
            }

            guard (200...299).contains(http.statusCode) else {
                completion(.failure("fetching imageUrl returned HTTP \(http.statusCode)"))
                return
            }

            guard let data = data else {
                completion(.failure("imageUrl returned no data"))
                return
            }

            guard data.count <= GlanceImageResolver.maxDownloadBytes else {
                completion(.failure(
                    "imageUrl is \(data.count) bytes, over the \(GlanceImageResolver.maxDownloadBytes) byte limit"
                ))
                return
            }

            completion(.success(data))
        }
        task.resume()
    }
}
