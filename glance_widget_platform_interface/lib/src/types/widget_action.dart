/// Types of actions that can be triggered from a widget.
enum GlanceActionType {
  /// Widget was tapped.
  tap,

  /// Widget refresh button was pressed.
  refresh,

  /// List item was tapped.
  itemTap,

  /// Checkbox was toggled.
  checkboxToggle,
}

/// Represents an action event from a Glance Widget.
class GlanceWidgetAction {
  /// The ID of the widget that triggered the action.
  final String widgetId;

  /// The type of action.
  final GlanceActionType type;

  /// Optional payload data (e.g., item index for list widgets).
  final Map<String, dynamic>? payload;

  /// Timestamp when the action occurred.
  final DateTime timestamp;

  const GlanceWidgetAction({
    required this.widgetId,
    required this.type,
    this.payload,
    required this.timestamp,
  });

  factory GlanceWidgetAction.fromMap(Map<String, dynamic> map) {
    return GlanceWidgetAction(
      widgetId: map['widgetId'] as String,
      type: GlanceActionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GlanceActionType.tap,
      ),
      payload: map['payload'] as Map<String, dynamic>?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'widgetId': widgetId,
        'type': type.name,
        'payload': payload,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  @override
  String toString() =>
      'GlanceWidgetAction(widgetId: $widgetId, type: $type, payload: $payload)';
}
