import SwiftUI
import Testing

/// The `fit` string is a contract with Dart, and the one part of this template
/// that has already broken in the field: the key drifted apart from what Dart
/// sends and nothing noticed. A compiler cannot catch a string that stops
/// matching a `switch`.
///
/// Dart's `ImageFit` has exactly three cases and sends `fit.name`, so the three
/// values below are the entire input domain -- plus whatever an older or newer
/// app sends, which is why the default matters as much as the cases.
///
/// These tests exist at all because the widget templates are now compiled into
/// this target alongside the extension that ships them. Before that they were
/// type-checked as loose files, and nothing in the repository could construct
/// one.
@Suite("Image widget fit mapping")
struct ImageWidgetFitTests {

    private func contentMode(for fit: String) -> ContentMode {
        ImageWidgetEntryView(
            entry: ImageWidgetEntry(
                date: Date(timeIntervalSince1970: 0),
                data: ImageWidgetData(
                    widgetId: "w",
                    title: "T",
                    imageUrl: nil,
                    imageBase64: nil,
                    imagePath: nil,
                    subtitle: nil,
                    fit: fit,
                    deepLinkUri: nil,
                    timestamp: 0,
                    theme: nil
                )
            )
        ).contentMode
    }

    @Test("contain is the only value that letterboxes")
    func containFits() {
        #expect(contentMode(for: "contain") == .fit)
    }

    @Test("cover and fill both crop")
    func coverAndFillFill() {
        // Not the same thing in Dart -- cover preserves the aspect ratio and
        // fill does not -- but SwiftUI's `ContentMode` has no third case, and
        // `.fill` is the closer of the two for both.
        #expect(contentMode(for: "cover") == .fill)
        #expect(contentMode(for: "fill") == .fill)
    }

    @Test("an unknown value fills rather than failing")
    func unknownFallsBack() {
        // A widget rendering nothing is worse than one cropping. This is the
        // case that catches an app built against a newer plugin than its
        // extension.
        #expect(contentMode(for: "") == .fill)
        #expect(contentMode(for: "scaleDown") == .fill)
        #expect(contentMode(for: "COVER") == .fill)
    }
}
