import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      debugShowCheckedModeBanner: false,
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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Simple widget state
  double _cryptoPrice = 94532.00;
  double _priceChange = 2.34;
  DebouncedWidgetController<SimpleWidgetData>? _cryptoController;
  SimpleWidgetController? _simpleController;
  Timer? _realtimeTimer;
  bool _isRealtimeActive = false;

  // Progress widget state
  double _downloadProgress = 0.0;
  Timer? _downloadTimer;
  ProgressWidgetController? _progressController;

  // List widget state
  final List<GlanceListItem> _todoItems = [
    const GlanceListItem(text: 'Buy groceries', checked: true),
    const GlanceListItem(text: 'Call mom', checked: false),
    const GlanceListItem(text: 'Finish report', checked: false),
    const GlanceListItem(text: 'Go to gym', checked: false),
  ];
  ListWidgetController? _listController;

  // Chart widget state
  List<double> _chartData = [12, 19, 15, 25, 22, 30, 28];
  ChartType _selectedChartType = ChartType.line;
  ChartWidgetController? _chartController;

  // Calendar widget state
  final List<CalendarEvent> _events = [
    const CalendarEvent(
      time: '09:00',
      title: 'Team Standup',
      color: Color(0xFF4CAF50),
    ),
    const CalendarEvent(
      time: '11:00',
      title: 'Design Review',
      color: Color(0xFF2196F3),
    ),
    const CalendarEvent(
      time: '14:00',
      title: 'Sprint Planning',
      color: Color(0xFFFFA726),
    ),
    const CalendarEvent(
      time: 'All Day',
      title: 'Project Deadline',
      color: Color(0xFFE53935),
      isAllDay: true,
    ),
  ];
  CalendarWidgetController? _calendarController;

  // Gauge widget state
  double _cpuUsage = 45.0;
  double _memoryUsage = 72.0;
  double _diskUsage = 58.0;
  GaugeType _selectedGaugeType = GaugeType.radial;
  GaugeWidgetController? _gaugeController;

  // Image widget state
  ImageWidgetController? _imageController;

  // Platform info
  StreamSubscription<GlanceWidgetAction>? _actionSubscription;
  bool _isPushSupported = false;
  String? _pushToken;
  bool _isBackgroundUpdateEnabled = false;
  String _backgroundUpdateStatus = 'Not configured';
  bool _isTimelineRefreshEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setupWidgetActions();
    _setDarkTheme();
    _checkPlatformFeatures();
    _initControllers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _downloadTimer?.cancel();
    _realtimeTimer?.cancel();
    _cryptoController?.dispose();
    _simpleController?.dispose();
    _progressController?.dispose();
    _listController?.dispose();
    _chartController?.dispose();
    _calendarController?.dispose();
    _gaugeController?.dispose();
    _imageController?.dispose();
    _actionSubscription?.cancel();
    super.dispose();
  }

  void _initControllers() {
    // Debounced controller for high-frequency crypto updates
    _cryptoController = DebouncedWidgetController<SimpleWidgetData>(
      widgetId: 'crypto_btc',
      theme: GlanceTheme.dark(),
      debounceInterval: const Duration(milliseconds: 100),
      maxWaitTime: const Duration(milliseconds: 500),
      stalenessThreshold: const Duration(seconds: 15),
    );

    // Type-safe convenience controllers for each widget type
    _simpleController = SimpleWidgetController(widgetId: 'crypto_btc');
    _progressController = ProgressWidgetController(widgetId: 'download_demo');
    _listController = ListWidgetController(widgetId: 'todo_demo');
    _chartController = ChartWidgetController(widgetId: 'chart_demo');
    _calendarController = CalendarWidgetController(widgetId: 'calendar_demo');
    _gaugeController = GaugeWidgetController(widgetId: 'gauge_demo');
    _imageController = ImageWidgetController(widgetId: 'photo_demo');
  }

  void _setupWidgetActions() {
    _actionSubscription = GlanceWidget.onAction.listen((action) {
      if (!mounted) return;

      String message = 'Widget ${action.widgetId}: ${action.type.name}';
      if (action.itemIndex != null) message += ' [item: ${action.itemIndex}]';
      if (action.value != null) message += ' [value: ${action.value}]';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2A2A3E),
        ),
      );

      // Handle checkbox toggles from widget
      if (action.type == GlanceActionType.checkboxToggle &&
          action.widgetId == 'todo_demo' &&
          action.itemIndex != null) {
        _toggleTodoItem(action.itemIndex!);
      }

      // Handle widget configuration requests
      if (action.type == GlanceActionType.configure) {
        _showConfigDialog(action.widgetId);
      }
    });
  }

  void _showConfigDialog(String widgetId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Configure Widget'),
        content: Text(
          'Widget "$widgetId" needs configuration.\nSelect what data to display.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              GlanceWidget.completeWidgetConfiguration(widgetId);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _setDarkTheme() async {
    await GlanceWidget.setTheme(GlanceTheme.dark());
  }

  Future<void> _checkPlatformFeatures() async {
    final isSupported = await GlanceWidget.isWidgetPushSupported();
    setState(() => _isPushSupported = isSupported);

    if (isSupported) {
      final token = await GlanceWidget.getWidgetPushToken();
      setState(() => _pushToken = token);
      if (kDebugMode && token != null) {
        debugPrint('Widget Push Token: $token');
      }
    }
  }

  // ── Simple Widget ──

  void _toggleRealtimeUpdates() {
    setState(() => _isRealtimeActive = !_isRealtimeActive);

    if (_isRealtimeActive) {
      _realtimeTimer = Timer.periodic(const Duration(milliseconds: 50), (
        timer,
      ) {
        final random = Random();
        final change = (random.nextDouble() - 0.5) * 100;
        setState(() {
          _cryptoPrice += change;
          _priceChange = (change / _cryptoPrice) * 100;
        });
        _cryptoController?.scheduleUpdate(
          SimpleWidgetData(
            title: 'Bitcoin',
            value: '\$${_cryptoPrice.toStringAsFixed(2)}',
            subtitle:
                '${_priceChange >= 0 ? '+' : ''}${_priceChange.toStringAsFixed(2)}%',
            subtitleColor: _priceChange >= 0 ? Colors.green : Colors.red,
            deepLinkUri: 'glancewidget://crypto/btc',
          ),
        );
      });
    } else {
      _realtimeTimer?.cancel();
      _realtimeTimer = null;
      _cryptoController?.flush();
    }
  }

  Future<void> _updateSimpleWidget() async {
    final random = Random();
    final change = (random.nextDouble() - 0.5) * 1000;
    setState(() {
      _cryptoPrice += change;
      _priceChange = (change / _cryptoPrice) * 100;
    });

    // v1.0: Use type-safe SimpleWidgetController with update()
    await _simpleController?.update(
      SimpleWidgetData(
        title: 'Bitcoin',
        value: '\$${_cryptoPrice.toStringAsFixed(2)}',
        subtitle:
            '${_priceChange >= 0 ? '+' : ''}${_priceChange.toStringAsFixed(2)}%',
        subtitleColor: _priceChange >= 0 ? Colors.green : Colors.red,
        deepLinkUri: 'glancewidget://crypto/btc',
      ),
    );
  }

  // ── Progress Widget ──

  void _startDownload() {
    setState(() => _downloadProgress = 0.0);
    _downloadTimer?.cancel();
    _downloadTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      setState(() => _downloadProgress += 0.02);

      // v1.0: Use type-safe ProgressWidgetController with update()
      await _progressController?.update(
        ProgressWidgetData(
          title: 'Downloading...',
          progress: _downloadProgress.clamp(0.0, 1.0),
          subtitle:
              '${(_downloadProgress * 100).toInt().clamp(0, 100)}% complete',
          progressType: ProgressType.circular,
          progressColor: Colors.blue,
          deepLinkUri: 'glancewidget://downloads',
        ),
      );

      if (_downloadProgress >= 1.0) {
        timer.cancel();
        await _progressController?.update(
          const ProgressWidgetData(
            title: 'Complete!',
            progress: 1.0,
            subtitle: 'Download finished',
            progressType: ProgressType.circular,
            progressColor: Colors.green,
          ),
        );
      }
    });
  }

  // ── List Widget ──

  Future<void> _updateListWidget() async {
    // v1.0: Use type-safe ListWidgetController with update()
    await _listController?.update(
      ListWidgetData(
        title: "Today's Tasks",
        items: _todoItems,
        showCheckboxes: true,
        deepLinkUri: 'glancewidget://todos',
      ),
    );
  }

  void _toggleTodoItem(int index) {
    if (index < 0 || index >= _todoItems.length) return;
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

  // ── Image Widget ──

  Future<void> _updateImageWidget() async {
    // Generate a simple gradient image as base64
    final base64Image = await _generateSampleImage();

    // v1.0: Use type-safe ImageWidgetController with update()
    await _imageController?.update(
      ImageWidgetData(
        title: 'Photo of the Day',
        imageBase64: base64Image,
        subtitle: 'Generated gradient',
        fit: ImageFit.cover,
        deepLinkUri: 'glancewidget://gallery',
      ),
    );
  }

  Future<String> _generateSampleImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(200, 200);

    // Draw gradient
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw circle
    final circlePaint = Paint()..color = Colors.white.withAlpha(77);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 60, circlePaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return base64Encode(bytes);
  }

  // ── Chart Widget ──

  Future<void> _updateChartWidget() async {
    // v1.0: Use type-safe ChartWidgetController with update()
    await _chartController?.update(
      ChartWidgetData(
        title: 'Revenue',
        dataPoints: _chartData,
        chartType: _selectedChartType,
        color: Colors.blue,
        subtitle: 'Last 7 days',
        deepLinkUri: 'glancewidget://analytics',
      ),
    );
  }

  void _randomizeChartData() {
    final random = Random();
    setState(() {
      _chartData = List.generate(7, (_) => random.nextDouble() * 50 + 10);
    });
    _updateChartWidget();
  }

  // ── Calendar Widget ──

  Future<void> _updateCalendarWidget() async {
    // v1.0: Use type-safe CalendarWidgetController with update()
    await _calendarController?.update(
      CalendarWidgetData(
        title: "Today's Events",
        date: DateTime.now(),
        events: _events,
        maxEvents: 5,
        deepLinkUri: 'glancewidget://calendar',
      ),
    );
  }

  // ── Gauge Widget ──

  Future<void> _updateGaugeWidget() async {
    // v1.0: Use type-safe GaugeWidgetController with update()
    await _gaugeController?.update(
      GaugeWidgetData(
        title: 'System Monitor',
        metrics: [
          GaugeMetric(
            label: 'CPU',
            value: _cpuUsage,
            maxValue: 100,
            color: Colors.green,
            unit: '%',
          ),
          GaugeMetric(
            label: 'Memory',
            value: _memoryUsage,
            maxValue: 100,
            color: Colors.orange,
            unit: '%',
          ),
          GaugeMetric(
            label: 'Disk',
            value: _diskUsage,
            maxValue: 100,
            color: Colors.blue,
            unit: '%',
          ),
        ],
        gaugeType: _selectedGaugeType,
        deepLinkUri: 'glancewidget://monitor',
      ),
    );
  }

  void _randomizeGaugeData() {
    final random = Random();
    setState(() {
      _cpuUsage = random.nextDouble() * 100;
      _memoryUsage = random.nextDouble() * 100;
      _diskUsage = random.nextDouble() * 100;
    });
    _updateGaugeWidget();
  }

  // ── Background Updates ──

  Future<void> _toggleBackgroundUpdates() async {
    if (_isBackgroundUpdateEnabled) {
      // v1.0: Background methods moved to GlanceBackground
      await GlanceBackground.cancelUpdate('crypto_btc');
      setState(() {
        _isBackgroundUpdateEnabled = false;
        _backgroundUpdateStatus = 'Cancelled';
      });
    } else {
      // v2.0: configuration either applies or throws with the reason.
      try {
        await GlanceBackground.configureUpdate(
          widgetId: 'crypto_btc',
          template: GlanceTemplate.simple,
          apiUrl:
              'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd&include_24hr_change=true',
          intervalMinutes: 15,
          title: 'Bitcoin',
          valuePath: r'$.bitcoin.usd',
          subtitlePath: r'$.bitcoin.usd_24h_change',
          valuePrefix: r'$',
        );
        setState(() {
          _isBackgroundUpdateEnabled = true;
          _backgroundUpdateStatus = 'Enabled (15 min interval)';
        });
      } on GlanceWidgetException catch (e) {
        setState(() {
          _isBackgroundUpdateEnabled = false;
          _backgroundUpdateStatus = 'Failed: ${e.message}';
        });
      }
    }
  }

  Future<void> _checkBackgroundUpdateStatus() async {
    final status = await GlanceBackground.getUpdateStatus('crypto_btc');
    setState(() {
      final isConfigured = status['isConfigured'] == true;
      final workState = status['workState'] ?? 'Unknown';
      _isBackgroundUpdateEnabled = isConfigured;
      _backgroundUpdateStatus = isConfigured
          ? 'State: $workState'
          : 'Not configured';
    });
  }

  Future<void> _testBackgroundUpdateNow() async {
    if (!_isBackgroundUpdateEnabled) {
      _showSnackBar('Please enable background updates first', Colors.orange);
      return;
    }
    try {
      await GlanceBackground.testUpdate('crypto_btc');
      _showSnackBar(
        'Test triggered! Check widget in a few seconds...',
        Colors.green,
      );
    } on GlanceWidgetException catch (e) {
      _showSnackBar('Failed to trigger test: ${e.message}', Colors.red);
    }
  }

  // ── Timeline Refresh (iOS) ──

  Future<void> _toggleTimelineRefresh() async {
    if (_isTimelineRefreshEnabled) {
      // v1.0: Timeline refresh moved to GlanceBackground
      await GlanceBackground.cancelTimelineRefresh('calendar_demo');
      setState(() => _isTimelineRefreshEnabled = false);
      _showSnackBar('Timeline refresh disabled', Colors.orange);
    } else {
      try {
        await GlanceBackground.configureTimelineRefresh(
          widgetId: 'calendar_demo',
          intervalMinutes: 30,
        );
        setState(() => _isTimelineRefreshEnabled = true);
        _showSnackBar('Timeline refresh enabled (30 min)', Colors.green);
      } on GlanceWidgetException catch (e) {
        setState(() => _isTimelineRefreshEnabled = false);
        _showSnackBar('Failed to configure: ${e.message}', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // ── BUILD ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glance Widget Demo'),
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFFFA726),
          labelColor: const Color(0xFFFFA726),
          unselectedLabelColor: Colors.grey,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Widgets'),
            Tab(text: 'Charts & Data'),
            Tab(text: 'Platform'),
            Tab(text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWidgetsTab(),
          _buildChartsTab(),
          _buildPlatformTab(),
          _buildInfoTab(),
        ],
      ),
    );
  }

  // ── TAB 1: Widgets ──

  Widget _buildWidgetsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection(
            title: 'Simple Widget',
            subtitle: 'Crypto prices, stats, metrics',
            icon: Icons.currency_bitcoin,
            color: const Color(0xFFFFA726),
            child: _buildSimpleWidgetDemo(),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Progress Widget',
            subtitle: 'Downloads, goals, tasks',
            icon: Icons.downloading,
            color: Colors.blue,
            child: _buildProgressWidgetDemo(),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'List Widget',
            subtitle: 'Todo lists, news, activities',
            icon: Icons.checklist,
            color: Colors.green,
            child: _buildListWidgetDemo(),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Image Widget',
            subtitle: 'Photos, artwork, thumbnails',
            icon: Icons.image,
            color: Colors.purple,
            child: _buildImageWidgetDemo(),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Charts & Data ──

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection(
            title: 'Chart Widget',
            subtitle: 'Line, bar, sparkline charts',
            icon: Icons.show_chart,
            color: Colors.blue,
            child: _buildChartWidgetDemo(),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Calendar Widget',
            subtitle: 'Events and schedule',
            icon: Icons.calendar_today,
            color: const Color(0xFFFFA726),
            child: _buildCalendarWidgetDemo(),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Gauge Widget',
            subtitle: 'System metrics, performance',
            icon: Icons.speed,
            color: Colors.green,
            child: _buildGaugeWidgetDemo(),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: Platform Features ──

  Widget _buildPlatformTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (Platform.isAndroid)
            _buildSection(
              title: 'Background Updates',
              subtitle: 'Updates when app is closed (15 min)',
              icon: Icons.cloud_sync,
              color: Colors.teal,
              child: _buildBackgroundUpdateDemo(),
            ),
          if (Platform.isAndroid) const SizedBox(height: 16),
          if (Platform.isIOS)
            _buildSection(
              title: 'Timeline Refresh',
              subtitle: 'Periodic widget refresh via WidgetKit',
              icon: Icons.timer,
              color: Colors.indigo,
              child: _buildTimelineRefreshDemo(),
            ),
          if (Platform.isIOS) const SizedBox(height: 16),
          _buildSection(
            title: 'Deep Links',
            subtitle: 'All widgets support custom deep link URIs',
            icon: Icons.link,
            color: Colors.cyan,
            child: _buildDeepLinkInfo(),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Widget Actions',
            subtitle: 'Tap, toggle, checkbox interactions',
            icon: Icons.touch_app,
            color: Colors.pink,
            child: _buildActionsInfo(),
          ),
          if (Platform.isAndroid) const SizedBox(height: 16),
          if (Platform.isAndroid)
            _buildSection(
              title: 'Lock Screen Widgets',
              subtitle: 'All widgets support lock screen placement',
              icon: Icons.lock,
              color: Colors.amber,
              child: _buildLockScreenInfo(),
            ),
        ],
      ),
    );
  }

  // ── TAB 4: Info ──

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoSection(),
          const SizedBox(height: 16),
          _buildPlatformInfoSection(),
          const SizedBox(height: 16),
          _buildTemplateOverview(),
        ],
      ),
    );
  }

  // ── SECTION BUILDER ──

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── SIMPLE WIDGET DEMO ──

  Widget _buildSimpleWidgetDemo() {
    return Column(
      children: [
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
        if (_cryptoController != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2A3E)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Updates', '${_cryptoController!.updateCount}'),
                _buildStat('Skipped', '${_cryptoController!.skippedCount}'),
                _buildStat('Stale', _cryptoController!.isStale ? 'Yes' : 'No'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildButton(
                'Update',
                Icons.refresh,
                const Color(0xFFFFA726),
                _updateSimpleWidget,
                dark: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                _isRealtimeActive ? 'Stop' : 'Realtime',
                _isRealtimeActive ? Icons.stop : Icons.play_arrow,
                _isRealtimeActive ? Colors.red : Colors.purple,
                _toggleRealtimeUpdates,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── PROGRESS WIDGET DEMO ──

  Widget _buildProgressWidgetDemo() {
    return Column(
      children: [
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
        const SizedBox(height: 12),
        _buildButton(
          'Start Download',
          Icons.download,
          Colors.blue,
          _downloadProgress > 0 && _downloadProgress < 1.0
              ? null
              : _startDownload,
          fullWidth: true,
        ),
      ],
    );
  }

  // ── LIST WIDGET DEMO ──

  Widget _buildListWidgetDemo() {
    return Column(
      children: [
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
                    "Today's Tasks",
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
        const SizedBox(height: 12),
        _buildButton(
          'Sync to Widget',
          Icons.sync,
          Colors.green,
          _updateListWidget,
          fullWidth: true,
        ),
      ],
    );
  }

  // ── IMAGE WIDGET DEMO ──

  Widget _buildImageWidgetDemo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 48, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Photo of the Day',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Generated gradient image',
                style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildButton(
          'Send to Widget',
          Icons.send,
          Colors.purple,
          _updateImageWidget,
          fullWidth: true,
        ),
        const SizedBox(height: 8),
        Text(
          'Generates a base64-encoded gradient image',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── CHART WIDGET DEMO ──

  Widget _buildChartWidgetDemo() {
    return Column(
      children: [
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
                    'Revenue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Last 7 days',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: CustomPaint(
                  size: const Size(double.infinity, 80),
                  painter: _MiniChartPainter(_chartData, _selectedChartType),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Chart type selector
        Row(
          children: ChartType.values.map((type) {
            final isSelected = _selectedChartType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != ChartType.sparkline ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedChartType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.withAlpha(51)
                          : const Color(0xFF0A0A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : const Color(0xFF3A3A4E),
                      ),
                    ),
                    child: Text(
                      type.name[0].toUpperCase() + type.name.substring(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.blue : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildButton(
                'Update',
                Icons.refresh,
                Colors.blue,
                _updateChartWidget,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                'Randomize',
                Icons.shuffle,
                const Color(0xFF3A3A4E),
                _randomizeChartData,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── CALENDAR WIDGET DEMO ──

  Widget _buildCalendarWidgetDemo() {
    final now = DateTime.now();
    return Column(
      children: [
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
                    "Today's Events",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${now.day}/${now.month}/${now.year}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF3A3A4E)),
              ..._events.map(
                (event) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: event.color ?? Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        event.time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (event.isAllDay)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'All Day',
                            style: TextStyle(fontSize: 10, color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildButton(
          'Send to Widget',
          Icons.calendar_month,
          const Color(0xFFFFA726),
          _updateCalendarWidget,
          fullWidth: true,
          dark: true,
        ),
      ],
    );
  }

  // ── GAUGE WIDGET DEMO ──

  Widget _buildGaugeWidgetDemo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              const Text(
                'System Monitor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGaugePreview('CPU', _cpuUsage, Colors.green),
                  _buildGaugePreview('Memory', _memoryUsage, Colors.orange),
                  _buildGaugePreview('Disk', _diskUsage, Colors.blue),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Gauge type selector
        Row(
          children: GaugeType.values.map((type) {
            final isSelected = _selectedGaugeType == type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: type != GaugeType.dashboard ? 8 : 0,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedGaugeType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.withAlpha(51)
                          : const Color(0xFF0A0A1A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Colors.green
                            : const Color(0xFF3A3A4E),
                      ),
                    ),
                    child: Text(
                      type.name[0].toUpperCase() + type.name.substring(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.green : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildButton(
                'Update',
                Icons.refresh,
                Colors.green,
                _updateGaugeWidget,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                'Randomize',
                Icons.shuffle,
                const Color(0xFF3A3A4E),
                _randomizeGaugeData,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGaugePreview(String label, double value, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value / 100,
                strokeWidth: 5,
                backgroundColor: const Color(0xFF3A3A4E),
                color: color,
              ),
              Text(
                '${value.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }

  // ── BACKGROUND UPDATE DEMO ──

  Widget _buildBackgroundUpdateDemo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _isBackgroundUpdateEnabled ? Icons.cloud_sync : Icons.cloud_off,
                color: _isBackgroundUpdateEnabled ? Colors.green : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isBackgroundUpdateEnabled ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _backgroundUpdateStatus,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildButton(
                _isBackgroundUpdateEnabled ? 'Disable' : 'Enable',
                _isBackgroundUpdateEnabled ? Icons.stop : Icons.play_arrow,
                _isBackgroundUpdateEnabled ? Colors.red : Colors.teal,
                _toggleBackgroundUpdates,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton(
                'Status',
                Icons.refresh,
                const Color(0xFF3A3A4E),
                _checkBackgroundUpdateStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildButton(
          'Test Now (Skip 15 min)',
          Icons.bolt,
          Colors.orange,
          _isBackgroundUpdateEnabled ? _testBackgroundUpdateNow : null,
          fullWidth: true,
          dark: true,
        ),
      ],
    );
  }

  // ── TIMELINE REFRESH DEMO (iOS) ──

  Widget _buildTimelineRefreshDemo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _isTimelineRefreshEnabled ? Icons.timer : Icons.timer_off,
                color: _isTimelineRefreshEnabled ? Colors.indigo : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTimelineRefreshEnabled ? 'Enabled' : 'Disabled',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isTimelineRefreshEnabled
                          ? 'Widgets refresh every ~30 minutes'
                          : 'Widgets only update when app triggers',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildButton(
          _isTimelineRefreshEnabled ? 'Disable' : 'Enable Timeline Refresh',
          _isTimelineRefreshEnabled ? Icons.stop : Icons.timer,
          _isTimelineRefreshEnabled ? Colors.red : Colors.indigo,
          _toggleTimelineRefresh,
          fullWidth: true,
        ),
        const SizedBox(height: 8),
        Text(
          'Uses WidgetKit .after(date) policy for periodic refresh',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── DEEP LINK INFO ──

  Widget _buildDeepLinkInfo() {
    final links = [
      ('Simple', 'glancewidget://crypto/btc'),
      ('Progress', 'glancewidget://downloads'),
      ('List', 'glancewidget://todos'),
      ('Image', 'glancewidget://gallery'),
      ('Chart', 'glancewidget://analytics'),
      ('Calendar', 'glancewidget://calendar'),
      ('Gauge', 'glancewidget://monitor'),
    ];

    return Column(
      children: links
          .map(
            (link) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      link.$1,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link.$2,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.cyan[300],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── ACTIONS INFO ──

  Widget _buildActionsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Widget interactions are received via GlanceWidget.onAction stream:',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        const SizedBox(height: 12),
        _buildActionItem('tap', 'When widget is tapped'),
        _buildActionItem('itemTap', 'When a list item is tapped'),
        _buildActionItem('checkboxToggle', 'When a checkbox is toggled'),
        _buildActionItem('toggle', 'When a toggle switch changes'),
        _buildActionItem('configure', 'When widget needs configuration'),
        _buildActionItem('refresh', 'When widget requests refresh'),
        const SizedBox(height: 8),
        Text(
          'Try tapping widgets on your home screen!',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(String type, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.pink.withAlpha(26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.pink,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  // ── LOCK SCREEN INFO ──

  Widget _buildLockScreenInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All 7 widget templates are configured with widgetCategory="home_screen|keyguard", '
          'allowing placement on both the home screen and lock screen.',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A1A),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.amber, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Long press lock screen → Add widget to access lock screen widgets.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── INFO SECTION ──

  Widget _buildInfoSection() {
    final isIOS = Platform.isIOS;
    final isAndroid = Platform.isAndroid;

    return _buildSection(
      title: 'How to Use',
      subtitle: 'Add widgets to your home screen',
      icon: Icons.info_outline,
      color: Colors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        ],
      ),
    );
  }

  Widget _buildPlatformInfoSection() {
    final isIOS = Platform.isIOS;
    final isAndroid = Platform.isAndroid;

    return _buildSection(
      title: 'Platform',
      subtitle: isIOS
          ? 'iOS (WidgetKit)'
          : isAndroid
          ? 'Android (Jetpack Glance)'
          : 'Unknown',
      icon: isIOS ? Icons.apple : Icons.android,
      color: isIOS ? Colors.white : Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlatformRow(
            Icons.widgets,
            'Templates: 7 (Simple, Progress, List, Image, Chart, Calendar, Gauge)',
          ),
          if (isAndroid)
            _buildPlatformRow(
              Icons.flash_on,
              'Instant updates (Jetpack Glance)',
            ),
          if (isAndroid)
            _buildPlatformRow(Icons.lock, 'Lock screen widgets supported'),
          if (isAndroid)
            _buildPlatformRow(
              Icons.cloud_sync,
              'Background updates (WorkManager)',
            ),
          if (isIOS)
            _buildPlatformRow(
              Icons.flash_on,
              'Instant updates when app is in foreground',
            ),
          if (isIOS)
            _buildPlatformRow(Icons.timer, 'Timeline refresh (.after policy)'),
          if (isIOS) ...[
            _buildPlatformRow(
              _isPushSupported ? Icons.check_circle : Icons.cancel,
              'Widget Push: ${_isPushSupported ? 'Supported (iOS 26+)' : 'Not available'}',
            ),
            if (_isPushSupported && _pushToken != null)
              _buildPlatformRow(
                Icons.vpn_key,
                'Push Token: ${_pushToken!.substring(0, min(16, _pushToken!.length))}...',
              ),
          ],
          _buildPlatformRow(Icons.link, 'Deep link support on all widgets'),
          _buildPlatformRow(Icons.touch_app, 'Interactive widget actions'),
        ],
      ),
    );
  }

  Widget _buildPlatformRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateOverview() {
    final templates = [
      (
        'Simple',
        Icons.currency_bitcoin,
        const Color(0xFFFFA726),
        'Title + Value + Subtitle',
      ),
      (
        'Progress',
        Icons.downloading,
        Colors.blue,
        'Circular or linear progress',
      ),
      ('List', Icons.checklist, Colors.green, 'Items with optional checkboxes'),
      ('Image', Icons.image, Colors.purple, 'Photo with title and subtitle'),
      ('Chart', Icons.show_chart, Colors.cyan, 'Line, bar, or sparkline'),
      ('Calendar', Icons.calendar_today, Colors.orange, 'Date with event list'),
      ('Gauge', Icons.speed, Colors.teal, 'Radial or dashboard metrics'),
    ];

    return _buildSection(
      title: 'Templates',
      subtitle: '7 widget templates available',
      icon: Icons.dashboard,
      color: Colors.purple,
      child: Column(
        children: templates
            .map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(t.$2, color: t.$3, size: 20),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 70,
                      child: Text(
                        t.$1,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.$4,
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── HELPERS ──

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onPressed, {
    bool fullWidth = false,
    bool dark = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: dark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
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

// ── MINI CHART PAINTER ──

class _MiniChartPainter extends CustomPainter {
  _MiniChartPainter(this.data, this.chartType);
  final List<double> data;
  final ChartType chartType;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    switch (chartType) {
      case ChartType.bar:
        final barWidth = size.width / data.length - 4;
        final barPaint = Paint()..color = Colors.blue;
        for (int i = 0; i < data.length; i++) {
          final barHeight = ((data[i] - minVal) / range) * size.height * 0.9;
          final x = i * (barWidth + 4) + 2;
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
            const Radius.circular(3),
          );
          canvas.drawRRect(rect, barPaint);
        }
        break;
      default:
        final path = Path();
        final stepX = data.length > 1
            ? size.width / (data.length - 1)
            : size.width;
        for (int i = 0; i < data.length; i++) {
          final x = i * stepX;
          final y =
              size.height - ((data[i] - minVal) / range) * size.height * 0.9;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, paint);

        // Fill for line chart
        if (chartType == ChartType.line) {
          final fillPath = Path.from(path)
            ..lineTo(size.width, size.height)
            ..lineTo(0, size.height)
            ..close();
          final fillPaint = Paint()
            ..shader = const LinearGradient(
              colors: [Color(0x402196F3), Color(0x002196F3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
          canvas.drawPath(fillPath, fillPaint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter old) =>
      old.data != data || old.chartType != chartType;
}
