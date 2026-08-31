/// Flutter package for creating instant-updating home screen widgets
/// for Android (Jetpack Glance) and iOS (WidgetKit).
///
/// This package provides 7 widget templates:
/// - **SimpleWidget**: Title + Value + Subtitle (crypto prices, weather)
/// - **ProgressWidget**: Circular/Linear progress bars (downloads, goals)
/// - **ListWidget**: Scrollable list with optional checkboxes (to-do, news)
/// - **ImageWidget**: Image display with title and subtitle
/// - **ChartWidget**: Line/Bar/Sparkline data visualization
/// - **CalendarWidget**: Date and event list display
/// - **GaugeWidget**: Radial or dashboard-style metrics
///
/// ## Getting Started
///
/// ```dart
/// import 'package:glance_widget/glance_widget.dart';
///
/// // Quick update with static API
/// await GlanceWidget.simple(
///   id: 'crypto_btc',
///   title: 'Bitcoin',
///   value: '\$94,532.00',
/// );
///
/// // Or use type-safe controllers
/// final ctrl = SimpleWidgetController(widgetId: 'crypto_btc');
/// await ctrl.update(SimpleWidgetData(title: 'Bitcoin', value: '\$94,532'));
/// ctrl.dispose();
/// ```
///
/// See the [README](https://github.com/abdullahtas0/glance_widget) for complete documentation.
library;

// Types (re-exported from platform interface)
export 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart'
    show
        WidgetData,
        GlanceTemplate,
        SimpleWidgetData,
        ProgressWidgetData,
        ProgressType,
        ListWidgetData,
        GlanceListItem,
        ImageWidgetData,
        ImageFit,
        ChartWidgetData,
        ChartType,
        CalendarWidgetData,
        CalendarEvent,
        GaugeWidgetData,
        GaugeMetric,
        GaugeType,
        GlanceTheme,
        GlanceWidgetAction,
        GlanceWidgetUpdate,
        GlanceWidgetBatchFailure,
        GlanceWidgetBatchException,
        GlanceActionType,
        GlanceWidgetException,
        GlanceWidgetTimeoutException,
        GlanceWidgetValidationException;

export 'src/controllers/calendar_widget_controller.dart';
export 'src/controllers/chart_widget_controller.dart';
export 'src/controllers/gauge_widget_controller.dart';
export 'src/controllers/image_widget_controller.dart';
export 'src/controllers/list_widget_controller.dart';
export 'src/controllers/progress_widget_controller.dart';
export 'src/controllers/simple_widget_controller.dart';
export 'src/debounced_widget_controller.dart';
export 'src/glance_background.dart';
export 'src/glance_config.dart';
// Core
export 'src/glance_widget.dart';
// Controllers
export 'src/glance_widget_controller.dart';
