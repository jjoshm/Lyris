import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/lyris_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/partner_shell.dart';
import 'services/sync_server.dart';
import 'services/foreground_sync_service.dart';
import 'providers/cycle_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LyrisForegroundService.init();
  runApp(ProviderScope(child: LyrisApp()));
}

class LyrisApp extends ConsumerWidget {
  LyrisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Lyris',
      debugShowCheckedModeBanner: false,
      theme: LyrisTheme.light,
      darkTheme: LyrisTheme.dark,
      themeMode: themeMode == LyrisThemeMode.light
          ? ThemeMode.light
          : themeMode == LyrisThemeMode.dark
              ? ThemeMode.dark
              : ThemeMode.system,
      themeAnimationDuration: Duration(milliseconds: 300),
      home: AppEntry(),
    );
  }
}

/// Shows onboarding on first launch, then routes based on role:
/// - tracker → MainShell (full app)
/// - partner → PartnerShell (read-only QR view)
class AppEntry extends StatefulWidget {
  AppEntry({super.key});

  /// Increment this to force AppEntry to re-read prefs (role switch).
  static final ValueNotifier<int> roleChanged = ValueNotifier(0);

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _loading = true;
  bool _onboardingDone = false;
  bool _isPartner = false;

  @override
  void initState() {
    super.initState();
    _checkPrefs();
    AppEntry.roleChanged.addListener(_checkPrefs);
  }

  @override
  void dispose() {
    AppEntry.roleChanged.removeListener(_checkPrefs);
    super.dispose();
  }

  Future<void> _checkPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _onboardingDone = prefs.getBool('onboarding_done') ?? false;
      _isPartner = prefs.getString('partner_mode') == 'partner';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_onboardingDone) {
      return OnboardingScreen(
        onComplete: () => _checkPrefs(), // re-read role after onboarding
      );
    }

    if (_isPartner) {
      return PartnerShell();
    }

    return MainShell();
  }
}

class MainShell extends ConsumerStatefulWidget {
  MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  void _onTaskData(Object data) {
    if (data == 'stop_sharing') {
      LyrisSyncServer.instance.stop();
      LyrisForegroundService.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    // Register data provider so restored server can serve fresh data
    LyrisSyncServer.instance.setDataProvider(_buildShareData);
    // Auto-restore WiFi sharing if it was enabled before app close
    LyrisSyncServer.restoreIfEnabled();
    // Listen for "Stop Sharing" button pressed in notification
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    super.dispose();
  }

  Map<String, dynamic> _buildShareData() {
    final prediction = ref.read(predictionProvider);
    final phase = ref.read(currentPhaseProvider);
    final cycleDay = ref.read(currentCycleDayProvider);

    // Period history for read-only calendar (last 12 months)
    final entries = ref.read(allPeriodEntriesProvider).value ?? [];
    final cutoff = DateTime.now().subtract(Duration(days: 365));
    final periodDates = entries
        .where((e) => e.date.isAfter(cutoff))
        .map((e) => '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}')
        .toSet()
        .toList();

    return {
      'v': 2,
      'type': 'lyris_share',
      'phase': phase.name,
      'phaseLabel': phase.label,
      'phaseEmoji': phase.emoji,
      'cycleDay': cycleDay,
      'cycleLength': prediction.predictedCycleLength,
      'periodLength': prediction.predictedPeriodLength,
      'nextPeriod': prediction.nextPeriodStart?.toIso8601String(),
      'ovulation': prediction.ovulationDay?.toIso8601String(),
      'fertileStart': prediction.fertileWindowStart.toIso8601String(),
      'fertileEnd': prediction.fertileWindowEnd.toIso8601String(),
      'pmsStart': prediction.pmsStart?.toIso8601String(),
      'confidence': prediction.confidence,
      'periodDates': periodDates,
      'sharedAt': DateTime.now().toIso8601String(),
    };
  }

  final _screens = [
    HomeScreen(),
    CalendarScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
