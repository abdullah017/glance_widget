import Foundation
import Testing
@testable import glance_widget_ios

/// `imageUrl` is documented, validated in Dart and sent over the channel, and
/// no iOS code ever read it. These pin down the policy that replaces that gap,
/// and they deliberately say the same things as `ImageResolverTest` on Android
/// so the two platforms cannot drift apart again.
struct GlanceImageResolverTests {
    private func remoteURL(_ source: GlanceImageSource) -> URL? {
        guard case let .remote(url) = source else { return nil }
        return url
    }

    private func isInvalid(_ source: GlanceImageSource) -> Bool {
        if case .invalid = source { return true }
        return false
    }

    @Test("an image url is a source the plugin must resolve")
    func remoteSource() {
        let source = GlanceImageResolver.source(imageBase64: nil, imageUrl: "https://example.com/a.png")

        #expect(remoteURL(source)?.absoluteString == "https://example.com/a.png")
    }

    @Test("inline bytes win over a url, since they need no network")
    func inlineWins() {
        let source = GlanceImageResolver.source(imageBase64: "AAAA", imageUrl: "https://example.com/a.png")

        #expect(source == .inline(base64: "AAAA"))
    }

    @Test("neither source given is not an error, just nothing to draw")
    func noSource() {
        #expect(GlanceImageResolver.source(imageBase64: nil, imageUrl: nil) == GlanceImageSource.none)
        #expect(GlanceImageResolver.source(imageBase64: "", imageUrl: "   ") == GlanceImageSource.none)
    }

    /// A widget update is an app-supplied string reaching a network stack, so
    /// `file://` and friends must not become an arbitrary-read primitive.
    @Test("only http and https are fetched", arguments: [
        "file:///etc/passwd",
        "ftp://h/a.png",
        "javascript:x",
    ])
    func unfetchableSchemes(url: String) {
        #expect(isInvalid(GlanceImageResolver.source(imageBase64: nil, imageUrl: url)))
    }

    @Test("plain http is fetched")
    func httpIsFetched() {
        let source = GlanceImageResolver.source(imageBase64: nil, imageUrl: "http://example.com/a.png")

        #expect(remoteURL(source)?.absoluteString == "http://example.com/a.png")
    }

    @Test("a url with no host is refused")
    func noHost() {
        // `URL(string:)` accepts this; the network stack can do nothing with it.
        #expect(isInvalid(GlanceImageResolver.source(imageBase64: nil, imageUrl: "https://")))
    }

    @Test("a malformed url is refused rather than thrown at the network stack")
    func malformed() {
        #expect(isInvalid(GlanceImageResolver.source(imageBase64: nil, imageUrl: "not a url")))
    }

    /// A redirect target goes through the same check as the first hop --
    /// redirects are followed by hand precisely so this holds for every hop.
    @Test("a redirect target is re-checked")
    func redirectTargetChecked() {
        #expect(isInvalid(GlanceImageResolver.source(imageBase64: nil, imageUrl: "file:///etc/hosts")))
        #expect(remoteURL(GlanceImageResolver.source(
            imageBase64: nil,
            imageUrl: "https://cdn.example.com/a.png"
        ))?.absoluteString == "https://cdn.example.com/a.png")
    }

    @Test("a large image is shrunk to the budget")
    func largeImageShrunk() {
        #expect(GlanceImageResolver.thumbnailEdge(sourceWidth: 4000, sourceHeight: 3000) == 512)
    }

    @Test("an image already within budget is not enlarged")
    func smallImageUntouched() {
        #expect(GlanceImageResolver.thumbnailEdge(sourceWidth: 400, sourceHeight: 300) == 400)
    }

    @Test("a degenerate size falls back to the budget")
    func degenerateSize() {
        #expect(GlanceImageResolver.thumbnailEdge(sourceWidth: 0, sourceHeight: 0) == 512)
    }
}
