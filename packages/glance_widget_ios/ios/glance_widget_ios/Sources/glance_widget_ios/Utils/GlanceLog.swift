import Foundation
import OSLog

/// The plugin's one logger.
///
/// Diagnostics used to go to `print()`, which reaches the Xcode console during
/// a debug run and nowhere at all on a device the developer is not attached to.
/// That is the wrong half of the problem: the failures worth reporting here --
/// an App Group the app holds no entitlement for, a widget payload that will
/// not encode -- all produce a widget that simply does not change, with no
/// crash and no error returned to Dart. Whoever is looking into it is holding
/// a phone, not a debugger.
///
/// `Logger` writes to the unified log, so those messages survive to Console.app
/// and to `sysdiagnose`. Filter on subsystem `dev.glance.widget`.
enum GlanceLog {
    static let subsystem = "dev.glance.widget"

    /// Storage, App Group resolution, and payload encoding.
    static let storage = Logger(subsystem: subsystem, category: "Storage")

    /// The method channel and the widget lifecycle.
    static let widget = Logger(subsystem: subsystem, category: "GlanceWidget")
}
