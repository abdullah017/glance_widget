import WidgetKit

/// The three shapes a home screen widget can be, as the templates lay them out.
///
/// The templates used to switch on `WidgetFamily` directly, which cannot be
/// exhaustive: the enum carries lock screen and Smart Stack families as well,
/// and Apple adds to it. Every one of those switches ended in `@unknown
/// default`, so `.systemExtraLarge` -- the iPad family, which exists today and
/// is not unknown at all -- silently took the `systemMedium` arm and rendered
/// an iPad-sized widget with phone-sized type.
///
/// Collapsing the families into the three the layouts actually distinguish
/// makes those switches exhaustive, so a family that is added later is a
/// compiler error in one file rather than a wrong number in fifty.
enum GlanceSystemSize {
    /// `.systemSmall` -- a square.
    case small

    /// `.systemMedium` -- a wide rectangle.
    case medium

    /// `.systemLarge` and `.systemExtraLarge` -- a tall rectangle, and the
    /// iPad's larger one, which wants the same generous type.
    case large

    /// Classifies [family], falling back to `.medium` for anything that is not
    /// a system family.
    ///
    /// The fallback is unreachable in practice: an accessory family is routed
    /// to its own view before any of this is asked for. It is here so that a
    /// family Apple adds after this was written renders at a sensible size
    /// rather than trapping.
    init(_ family: WidgetFamily) {
        switch family {
        case .systemSmall:
            self = .small
        case .systemLarge, .systemExtraLarge:
            self = .large
        case .systemMedium:
            self = .medium
        default:
            self = .medium
        }
    }
}

/// The lock screen and Smart Stack families, which get their own layouts.
///
/// These are drawn from a tiny amount of space in a single tint colour. A
/// system layout scaled down into one is unreadable, so each template builds
/// something else for them entirely.
enum GlanceAccessorySize {
    /// `.accessoryCircular` -- a ring roughly 58pt across.
    case circular

    /// `.accessoryRectangular` -- about 160x72pt, room for two or three lines.
    case rectangular

    /// `.accessoryInline` -- one line beside the lock screen clock.
    case inline

    /// Classifies [family], or nil when it is a system family.
    init?(_ family: WidgetFamily) {
        switch family {
        case .accessoryCircular:
            self = .circular
        case .accessoryRectangular:
            self = .rectangular
        case .accessoryInline:
            self = .inline
        default:
            return nil
        }
    }
}
