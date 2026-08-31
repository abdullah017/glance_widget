import Foundation

/// Where an image widget's picture comes from.
public enum GlanceImageSource: Equatable {
    /// Bytes the app already supplied; nothing to fetch.
    case inline(base64: String)

    /// An address the plugin has to fetch before the widget can draw.
    case remote(url: URL)

    /// An address the plugin refuses to fetch, and why.
    case invalid(reason: String)

    /// Neither source was supplied. Not an error -- just nothing to draw.
    case none
}

/// Decides what an image widget update is pointing at, and how far a picture
/// has to shrink before a widget extension can hold it.
///
/// Deliberately free of WidgetKit and UIKit, so both decisions can be tested
/// without a host. Mirrors `ImageResolver` on Android; the two policies are
/// meant to stay identical, and the tests on each side say the same things.
public enum GlanceImageResolver {
    /// Only these are fetched. A widget update carries an app-supplied string
    /// into a network stack, so `file://` must not become a way to read
    /// arbitrary local data.
    private static let fetchableSchemes: Set<String> = ["http", "https"]

    /// A widget extension's memory budget is far tighter than an app's, and the
    /// picture still has to cross into WidgetKit.
    public static let maxEdgePixels = 512

    /// Bounds a redirect chain, which is followed by hand so that every hop is
    /// re-checked.
    public static let maxRedirects = 5

    /// Refuses anything larger before a byte of it is decoded.
    public static let maxDownloadBytes = 16 * 1024 * 1024

    public static func source(imageBase64: String?, imageUrl: String?) -> GlanceImageSource {
        // Inline bytes win: they are already here and need no network.
        if let base64 = imageBase64, !base64.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .inline(base64: base64)
        }

        guard let raw = imageUrl,
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .none
        }

        guard let url = URL(string: raw), let scheme = url.scheme else {
            return .invalid(reason: "imageUrl is not a valid URL: '\(raw)'")
        }

        guard fetchableSchemes.contains(scheme.lowercased()) else {
            return .invalid(reason: "imageUrl scheme '\(scheme)' is not fetchable: '\(raw)'")
        }

        // `URL(string:)` accepts a scheme with no host, which would reach the
        // network stack as a request that can never succeed.
        guard let host = url.host, !host.isEmpty else {
            return .invalid(reason: "imageUrl has no host: '\(raw)'")
        }

        return .remote(url: url)
    }

    /// The longest edge to decode to, so a picture lands at or below
    /// [maxEdgePixels] without being enlarged if it is already small.
    public static func thumbnailEdge(sourceWidth: Int, sourceHeight: Int) -> Int {
        let longest = max(sourceWidth, sourceHeight)
        guard longest > 0 else { return maxEdgePixels }
        return min(longest, maxEdgePixels)
    }
}
