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

  /// A toggle element was switched.
  toggle,

  /// Widget needs configuration (e.g., when first added to home screen).
  configure,
}

/// Represents an action event from a Glance Widget.
class GlanceWidgetAction {
  /// Creates an action event describing an interaction with a widget.
  const GlanceWidgetAction({
    required this.widgetId,
    required this.type,
    this.payload,
    required this.timestamp,
    this.itemId,
    this.value,
    this.itemIndex,
  });

  /// Rebuilds an action from the map delivered over the event channel.
  ///
  /// An unrecognised `type` falls back to [GlanceActionType.tap].
  factory GlanceWidgetAction.fromMap(Map<String, dynamic> map) {
    final payload = map['payload'] as Map<String, dynamic>?;

    return GlanceWidgetAction(
      widgetId: map['widgetId'] as String,
      type: GlanceActionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => GlanceActionType.tap,
      ),
      payload: payload,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      itemId: map['itemId'] as String? ?? payload?['itemId'] as String?,
      value: map['value'] as bool? ?? payload?['value'] as bool?,
      itemIndex: _parseItemIndex(map, payload),
    );
  }

  /// The ID of the widget that triggered the action.
  final String widgetId;

  /// The type of action.
  final GlanceActionType type;

  /// Optional payload data (e.g., item index for list widgets).
  final Map<String, dynamic>? payload;

  /// Timestamp when the action occurred.
  final DateTime timestamp;

  /// Optional identifier for the item that was interacted with.
  final String? itemId;

  /// Optional boolean value for toggle/checkbox state.
  final bool? value;

  /// Optional index for list item interactions.
  final int? itemIndex;

  /// Parses the itemIndex from either the top-level map or the payload.
  static int? _parseItemIndex(
    Map<String, dynamic> map,
    Map<String, dynamic>? payload,
  ) {
    final topLevel = map['itemIndex'];
    if (topLevel is int) return topLevel;
    if (topLevel is String) return int.tryParse(topLevel);

    final fromPayload = payload?['itemIndex'] ?? payload?['index'];
    if (fromPayload is int) return fromPayload;
    if (fromPayload is String) return int.tryParse(fromPayload);

    return null;
  }

  /// Serialises this action for transport over a platform channel.
  Map<String, dynamic> toMap() => {
    'widgetId': widgetId,
    'type': type.name,
    'payload': payload,
    'timestamp': timestamp.millisecondsSinceEpoch,
    if (itemId != null) 'itemId': itemId,
    if (value != null) 'value': value,
    if (itemIndex != null) 'itemIndex': itemIndex,
  };

  @override
  String toString() =>
      'GlanceWidgetAction(widgetId: $widgetId, type: $type, payload: $payload'
      '${itemId != null ? ', itemId: $itemId' : ''}'
      '${value != null ? ', value: $value' : ''}'
      '${itemIndex != null ? ', itemIndex: $itemIndex' : ''}'
      ')';
}
