import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glance_widget/glance_widget.dart';

/// Drives one Live Activity through its whole life, because that is the part
/// of the API that cannot be judged from a screenshot: an activity started,
/// updated a few times and ended is a different thing from one that appears.
///
/// It is also the only way to see it at all -- a Live Activity is drawn by the
/// widget extension on the Lock Screen and in the Dynamic Island, never inside
/// the app.
class LiveActivityPage extends StatefulWidget {
  const LiveActivityPage({super.key});

  @override
  State<LiveActivityPage> createState() => _LiveActivityPageState();
}

class _LiveActivityPageState extends State<LiveActivityPage> {
  static const _activityId = 'demo-delivery';

  bool? _enabled;
  bool _running = false;
  int _minutesAway = 12;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    unawaited(_checkAvailability());
  }

  Future<void> _checkAvailability() async {
    final enabled = await GlanceWidget.areLiveActivitiesEnabled();
    // The activity outlives this process. Coming back to a page that has
    // forgotten it would offer Start for something already on screen, and
    // Start refuses a duplicate id -- so ask rather than assume.
    final running = await GlanceWidget.isLiveActivityRunning(_activityId);
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _running = running;
      });
    }
  }

  LiveActivityContent get _content => LiveActivityContent(
    title: '🛵 Order on its way',
    status: _minutesAway > 0 ? '$_minutesAway min away' : 'Arriving now',
    progress: (12 - _minutesAway) / 12,
    stats: const {'Driver': 'Sam', 'Items': '3'},
  );

  /// Every call here can fail for a reason worth showing: the user turned Live
  /// Activities off, the activity was dismissed by hand, the platform has none.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _lastError = null);
    try {
      await action();
    } on UnsupportedError catch (e) {
      setState(() => _lastError = e.message?.toString() ?? 'Unsupported');
    } on GlanceWidgetException catch (e) {
      setState(() => _lastError = '${e.code}: ${e.message}');
    }
  }

  Future<void> _start() => _run(() async {
    await GlanceWidget.startLiveActivity(
      activityId: _activityId,
      content: _content,
    );
    if (mounted) setState(() => _running = true);
  });

  Future<void> _tick() => _run(() async {
    setState(() => _minutesAway = (_minutesAway - 3).clamp(0, 12));
    await GlanceWidget.updateLiveActivity(
      activityId: _activityId,
      content: _content,
    );
  });

  Future<void> _end(LiveActivityDismissal dismissal) => _run(() async {
    await GlanceWidget.endLiveActivity(
      activityId: _activityId,
      content: const LiveActivityContent(
        title: '🛵 Order delivered',
        status: 'Left at your door',
        progress: 1,
      ),
      dismissal: dismissal,
    );
    if (mounted) setState(() => _running = false);
  });

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return Scaffold(
      appBar: AppBar(title: const Text('Live Activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                enabled ?? false ? Icons.check_circle : Icons.block,
                color: enabled ?? false ? Colors.green : Colors.orange,
              ),
              title: Text(switch (enabled) {
                null => 'Checking…',
                true => 'Live Activities are available',
                false => 'Not available here',
              }),
              subtitle: const Text(
                'iOS 16.2+, and the user can turn them off per app in '
                'Settings. Android and desktop answer false rather than '
                'throwing, which is why this is the call to branch on.',
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_lastError != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(_lastError!),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: (enabled ?? false) && !_running ? _start : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _running ? _tick : null,
            icon: const Icon(Icons.update),
            label: Text('Advance to ${(_minutesAway - 3).clamp(0, 12)} min'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _running
                ? () => _end(LiveActivityDismissal.standard)
                : null,
            icon: const Icon(Icons.stop),
            label: const Text('End (stays readable a while)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _running
                ? () => _end(LiveActivityDismissal.immediate)
                : null,
            icon: const Icon(Icons.close),
            label: const Text('End immediately'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Lock the device, or leave the app, to see it. A Live Activity is '
            'drawn by the widget extension -- never inside the app that '
            'started it.',
          ),
        ],
      ),
    );
  }
}
