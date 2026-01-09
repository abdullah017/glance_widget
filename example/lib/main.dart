import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';

import 'package:glance_widget/glance_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glance Widget Demo',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFA726),
          secondary: Color(0xFF2196F3),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Simple widget state
  double _cryptoPrice = 94532.00;
  double _priceChange = 2.34;

  // Progress widget state
  double _downloadProgress = 0.0;
  Timer? _downloadTimer;

  // List widget state
  final List<GlanceListItem> _todoItems = [
    const GlanceListItem(text: 'Buy groceries', checked: true),
    const GlanceListItem(text: 'Call mom', checked: false),
    const GlanceListItem(text: 'Finish report', checked: false),
    const GlanceListItem(text: 'Go to gym', checked: false),
  ];

  StreamSubscription<GlanceWidgetAction>? _actionSubscription;

  // Platform info
  bool _isPushSupported = false;
  String? _pushToken;

  @override
  void initState() {
    super.initState();
    _setupWidgetActions();
    _setDarkTheme();
    _checkPlatformFeatures();
  }

  @override
  void dispose() {
    _downloadTimer?.cancel();
    _actionSubscription?.cancel();
    super.dispose();
  }

  void _setupWidgetActions() {
    _actionSubscription = GlanceWidget.onAction.listen((action) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Widget ${action.widgetId}: ${action.type.name}'),
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  Future<void> _setDarkTheme() async {
    await GlanceWidget.setTheme(GlanceTheme.dark());
  }

  Future<void> _checkPlatformFeatures() async {
    // Check if Widget Push Updates are supported (iOS 26+)
    final isSupported = await GlanceWidget.isWidgetPushSupported();
    setState(() {
      _isPushSupported = isSupported;
    });

    if (isSupported) {
      final token = await GlanceWidget.getWidgetPushToken();
      setState(() {
        _pushToken = token;
      });
      if (kDebugMode && token != null) {
        print('Widget Push Token: $token');
      }
    }
  }

  Future<void> _updateSimpleWidget() async {
    // Simulate price change
    final random = Random();
    final change = (random.nextDouble() - 0.5) * 1000;
    setState(() {
      _cryptoPrice += change;
      _priceChange = (change / _cryptoPrice) * 100;
    });

    await GlanceWidget.simple(
      id: 'crypto_btc',
      title: 'Bitcoin',
      value: '\$${_cryptoPrice.toStringAsFixed(2)}',
      subtitle:
          '${_priceChange >= 0 ? '+' : ''}${_priceChange.toStringAsFixed(2)}%',
      subtitleColor: _priceChange >= 0 ? Colors.green : Colors.red,
    );
  }

  void _startDownload() {
    setState(() {
      _downloadProgress = 0.0;
    });

    _downloadTimer?.cancel();
    _downloadTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      setState(() {
        _downloadProgress += 0.02;
      });

      await GlanceWidget.progress(
        id: 'download_demo',
        title: 'Downloading...',
        progress: _downloadProgress.clamp(0.0, 1.0),
        subtitle:
            '${(_downloadProgress * 100).toInt().clamp(0, 100)}% complete',
        progressType: ProgressType.circular,
        progressColor: Colors.blue,
      );

      if (_downloadProgress >= 1.0) {
        timer.cancel();
        await GlanceWidget.progress(
          id: 'download_demo',
          title: 'Complete!',
          progress: 1.0,
          subtitle: 'Download finished',
          progressType: ProgressType.circular,
          progressColor: Colors.green,
        );
      }
    });
  }

  Future<void> _updateListWidget() async {
    await GlanceWidget.list(
      id: 'todo_demo',
      title: 'Today\'s Tasks',
      items: _todoItems,
      showCheckboxes: true,
    );
  }

  void _toggleTodoItem(int index) {
    setState(() {
      final item = _todoItems[index];
      _todoItems[index] = GlanceListItem(
        text: item.text,
        checked: !item.checked,
        secondaryText: item.secondaryText,
      );
    });
    _updateListWidget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glance Widget Demo'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Simple Widget Section
            _buildSection(
              title: 'Simple Widget',
              subtitle: 'Perfect for prices, stats, metrics',
              child: _buildSimpleWidgetDemo(),
            ),

            const SizedBox(height: 24),

            // Progress Widget Section
            _buildSection(
              title: 'Progress Widget',
              subtitle: 'Downloads, goals, tasks',
              child: _buildProgressWidgetDemo(),
            ),

            const SizedBox(height: 24),

            // List Widget Section
            _buildSection(
              title: 'List Widget',
              subtitle: 'Todo lists, news, activities',
              child: _buildListWidgetDemo(),
            ),

            const SizedBox(height: 24),

            // Info Section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSimpleWidgetDemo() {
    return Column(
      children: [
        // Preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Bitcoin',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${_cryptoPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_priceChange >= 0 ? '+' : ''}${_priceChange.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _priceChange >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _updateSimpleWidget,
          icon: const Icon(Icons.refresh),
          label: const Text('Update Widget'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA726),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressWidgetDemo() {
    return Column(
      children: [
        // Preview
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: _downloadProgress.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: const Color(0xFF3A3A4E),
                      color: _downloadProgress >= 1.0
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
                  Text(
                    '${(_downloadProgress * 100).toInt().clamp(0, 100)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _downloadProgress >= 1.0 ? 'Complete!' : 'Downloading...',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _downloadProgress > 0 && _downloadProgress < 1.0
              ? null
              : _startDownload,
          icon: const Icon(Icons.download),
          label: const Text('Start Download'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildListWidgetDemo() {
    return Column(
      children: [
        // Preview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Today\'s Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_todoItems.where((i) => i.checked).length}/${_todoItems.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF3A3A4E)),
              ...List.generate(_todoItems.length, (index) {
                final item = _todoItems[index];
                return InkWell(
                  onTap: () => _toggleTodoItem(index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          item.checked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: item.checked ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: item.checked ? Colors.grey : Colors.white,
                            decoration: item.checked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _updateListWidget,
          icon: const Icon(Icons.sync),
          label: const Text('Sync to Widget'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final isIOS = Platform.isIOS;
    final isAndroid = Platform.isAndroid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'How to Use',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isAndroid) ...[
            _buildInfoItem('1. Long press on home screen'),
            _buildInfoItem('2. Select "Widgets"'),
            _buildInfoItem('3. Find "Glance Widget" and drag to home'),
            _buildInfoItem('4. Use this app to update widgets'),
          ] else if (isIOS) ...[
            _buildInfoItem('1. Long press on home screen'),
            _buildInfoItem('2. Tap "+" in top left corner'),
            _buildInfoItem('3. Search for this app'),
            _buildInfoItem('4. Select widget size and tap "Add"'),
          ] else ...[
            _buildInfoItem('Widgets require Android or iOS'),
          ],
          const SizedBox(height: 16),
          const Divider(color: Color(0xFF3A3A4E)),
          const SizedBox(height: 8),
          _buildPlatformInfo(isIOS, isAndroid),
        ],
      ),
    );
  }

  Widget _buildPlatformInfo(bool isIOS, bool isAndroid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isIOS ? Icons.apple : Icons.android,
              color: Colors.grey[400],
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Platform: ${isIOS ? 'iOS' : isAndroid ? 'Android' : 'Unknown'}',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
        if (isIOS) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _isPushSupported ? Icons.check_circle : Icons.cancel,
                color: _isPushSupported ? Colors.green : Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Widget Push: ${_isPushSupported ? 'Supported (iOS 26+)' : 'Not available'}',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
          if (_isPushSupported && _pushToken != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.vpn_key, color: Colors.grey[400], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Push Token: ${_pushToken!.substring(0, 16)}...',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
        if (isAndroid) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Instant updates (Jetpack Glance)',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: Colors.grey[300]),
      ),
    );
  }
}
