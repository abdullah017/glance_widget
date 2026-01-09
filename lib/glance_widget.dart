/// Flutter package for creating instant-updating Android home screen widgets
/// using Jetpack Glance.
///
/// This package provides three widget templates:
/// - **SimpleWidget**: Title + Value + Subtitle (perfect for crypto prices, weather)
/// - **ProgressWidget**: Circular/Linear progress bars (downloads, goals)
/// - **ListWidget**: Scrollable list with optional checkboxes (to-do, news)
///
/// ## Getting Started
///
/// ```dart
/// import 'package:glance_widget/glance_widget.dart';
///
/// // Update a simple widget
/// await GlanceWidget.simple(
///   id: 'crypto_btc',
///   title: 'Bitcoin',
///   value: '\$94,532.00',
///   subtitle: '+2.34%',
///   subtitleColor: Colors.green,
/// );
/// ```
///
/// See the [README](https://github.com/abdullah017/glance_widget) for complete documentation.
library;

export 'src/glance_widget.dart';
export 'src/glance_widget_controller.dart';

// Re-export types from platform interface
export 'package:glance_widget_platform_interface/glance_widget_platform_interface.dart'
    show
        SimpleWidgetData,
        ProgressWidgetData,
        ProgressType,
        ListWidgetData,
        GlanceListItem,
        GlanceTheme,
        GlanceWidgetAction,
        GlanceActionType,
        GlanceWidgetException,
        GlanceWidgetTimeoutException,
        GlanceWidgetValidationException,
        MethodChannelGlanceWidget;
