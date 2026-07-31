import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lyris_crypto.dart';
import 'secure_token_store.dart';

/// Foreground service for Lyris WiFi sync — two modes:
///
/// **Tracker mode** (broadcaster): advertises mDNS so the partner can find us.
///   - Broadcasts 30s, pauses 5 min, repeats. Always runs regardless of battery.
///
/// **Partner mode** (receiver): keeps the read-only app alive in the background
///   and periodically fetches fresh data from the tracker.
///   - Discovers + fetches every 5 min. Always runs regardless of battery.
class LyrisForegroundService {
  LyrisForegroundService._();

  static const String _prefKey = 'fg_service_running';
  static const String _modePrefKey = 'fg_service_mode'; // 'tracker' or 'partner'
  static const int _cycleIntervalMs = 330000; // 5.5 min (30s broadcast + 5 min pause)

  static bool _isRunning = false;
  static bool get isRunning => _isRunning;

  /// Initialize the foreground task plugin. Call once in main().
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'lyris_sync_channel',
        channelName: 'Lyris Sync',
        channelDescription: 'Keeps cycle sync active between partners',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        playSound: false,
        showWhen: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_cycleIntervalMs),
        autoRunOnBoot: false,
        allowWakeLock: false,
        allowWifiLock: true,
        allowAutoRestart: true,
      ),
    );
  }

  /// Start in tracker mode (mDNS broadcaster).
  static Future<bool> startTracker() async {
    return _start('tracker', 'Lyris Sharing Active', 'Partner can see your cycle on this WiFi');
  }

  /// Start in partner mode (background sync receiver).
  static Future<bool> startPartner() async {
    return _start('partner', 'Lyris Partner Sync', 'Receiving cycle updates in background');
  }

  static Future<bool> _start(String mode, String title, String text) async {
    if (_isRunning) return true;

    final result = await FlutterForegroundTask.startService(
      notificationTitle: title,
      notificationText: text,
      notificationButtons: [
        const NotificationButton(id: 'stop', text: 'Stop'),
      ],
      callback: _taskCallback,
    );

    if (result is ServiceRequestSuccess) {
      _isRunning = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      await prefs.setString(_modePrefKey, mode);
      debugPrint('[LyrisFG] Foreground service started ($mode mode)');
    } else {
      debugPrint('[LyrisFG] Failed to start: $result');
    }
    return result is ServiceRequestSuccess;
  }

  /// Stop the foreground service.
  static Future<void> stop() async {
    if (!_isRunning) return;
    await FlutterForegroundTask.stopService();
    _isRunning = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, false);
    await prefs.remove(_modePrefKey);
    debugPrint('[LyrisFG] Foreground service stopped');
  }

  /// Restore service if it was running before app restart.
  static Future<void> restoreIfRunning() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) ?? false) {
      final mode = prefs.getString(_modePrefKey) ?? 'tracker';
      if (mode == 'partner') {
        await startPartner();
      } else {
        await startTracker();
      }
    }
  }
}

/// Top-level callback for the foreground task isolate.
@pragma('vm:entry-point')
void _taskCallback() {
  FlutterForegroundTask.setTaskHandler(_SyncTaskHandler());
}

/// Task handler — runs in a separate isolate.
/// Reads the mode from SharedPreferences and acts accordingly.
class _SyncTaskHandler extends TaskHandler {
  BonsoirBroadcast? _broadcast;
  bool _broadcasting = false;
  int _cycleCount = 0;
  String _mode = 'tracker';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    _mode = prefs.getString('fg_service_mode') ?? 'tracker';
    debugPrint('[LyrisFG] Task started ($_mode mode) by ${starter.name}');

    if (_mode == 'tracker') {
      await _startBroadcastCycle();
    } else {
      await _partnerSyncCycle();
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_mode == 'tracker') {
      _startBroadcastCycle();
    } else {
      _partnerSyncCycle();
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _stopBroadcast();
    debugPrint('[LyrisFG] Task destroyed');
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      // Stop directly from the task isolate — works even when app is backgrounded.
      _stopBroadcast();
      FlutterForegroundTask.stopService();
      // Persist the preference so it doesn't auto-restart
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('sync_sharing_enabled', false);
      });
      // Also notify main isolate if it's alive (updates UI state)
      FlutterForegroundTask.sendDataToMain('stop_sharing');
    }
  }

  // ─── TRACKER MODE: persistent mDNS broadcast ─────────────────────────

  Future<void> _startBroadcastCycle() async {
    // mDNS broadcast is essentially free (OS-level UDP multicast, no CPU wake).
    // Keep it running persistently so the partner can ALWAYS find us,
    // regardless of timing. No intervals needed.
    if (_broadcasting) return; // already running

    _cycleCount++;
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Lyris Sharing Active',
      notificationText: 'Discoverable to partner • Since ${_formatTime(DateTime.now())}',
    );

    try {
      _broadcast = BonsoirBroadcast(
        service: BonsoirService(
          name: 'Lyris Tracker',
          type: '_lyris-sync._tcp',
          port: 48291,
          attributes: {
            'version': '2',
            'encrypted': 'true',
          },
        ),
      );
      await _broadcast!.ready;
      await _broadcast!.start();
      _broadcasting = true;
      debugPrint('[LyrisFG] mDNS broadcast started (persistent)');
    } catch (e) {
      debugPrint('[LyrisFG] Broadcast error: $e');
    }
  }

  Future<void> _stopBroadcast() async {
    if (_broadcasting) {
      await _broadcast?.stop();
      _broadcast = null;
      _broadcasting = false;
    }
  }

  // ─── PARTNER MODE: discover + fetch encrypted data (with retries) ────

  Future<void> _partnerSyncCycle() async {
    _cycleCount++;
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Lyris Partner Sync',
      notificationText: 'Syncing… (cycle #$_cycleCount)',
    );

    try {
      final authToken = await SecureTokenStore.read();
      if (authToken == null) {
        debugPrint('[LyrisFG] No pairing token — cannot sync');
        return;
      }

      // Retry discovery up to 3 times (tracker might not be broadcasting yet)
      String? host;
      int? port;

      for (int attempt = 1; attempt <= 3; attempt++) {
        final result = await _discoverTracker();
        if (result != null) {
          host = result.$1;
          port = result.$2;
          break;
        }
        if (attempt < 3) {
          debugPrint('[LyrisFG] Discovery attempt $attempt failed — retrying in 10s');
          await Future.delayed(const Duration(seconds: 10));
        }
      }

      if (host == null || port == null) {
        debugPrint('[LyrisFG] Tracker not found after 3 attempts');
        await FlutterForegroundTask.updateService(
          notificationTitle: 'Lyris Partner Sync',
          notificationText: 'Waiting for tracker… (next try in 5 min)',
        );
        return;
      }

      // Fetch encrypted data
      final key = await LyrisCrypto.deriveKey(authToken);
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse('http://$host:$port/sync'));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final envelope = jsonDecode(body) as Map<String, dynamic>;

        if (envelope['v'] == 2 && envelope['e'] != null) {
          // Validate the payload decrypts before caching it. We store the
          // authenticated ciphertext verbatim — never plaintext — so the
          // on-device cache is encrypted at rest with the pairing key.
          await LyrisCrypto.decrypt(envelope['e'] as String, key);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('partner_data', body);
          debugPrint('[LyrisFG] Partner sync successful ✓');

          await FlutterForegroundTask.updateService(
            notificationTitle: 'Lyris Partner Sync',
            notificationText: 'Last sync: ${_formatTime(DateTime.now())} ✓',
          );
        }
      }
      client.close();
    } catch (e) {
      debugPrint('[LyrisFG] Partner sync error: $e');
      await FlutterForegroundTask.updateService(
        notificationTitle: 'Lyris Partner Sync',
        notificationText: 'Sync failed — retrying in 5 min',
      );
    }
  }

  /// Single mDNS discovery attempt. Returns (host, port) or null.
  Future<(String, int)?> _discoverTracker() async {
    final discovery = BonsoirDiscovery(type: '_lyris-sync._tcp');
    await discovery.ready;

    String? host;
    int? port;
    final completer = Completer<void>();

    final sub = discovery.eventStream!.listen((event) async {
      if (event.type == BonsoirDiscoveryEventType.discoveryServiceFound) {
        final service = event.service;
        if (service != null) {
          await service.resolve(discovery.serviceResolver);
        }
      } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
        final resolved = event.service as ResolvedBonsoirService;
        host = resolved.host;
        port = resolved.port;
        if (!completer.isCompleted) completer.complete();
      }
    });

    await discovery.start();

    // Wait up to 10s per attempt
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
    await sub.cancel();
    await discovery.stop();

    if (host != null && port != null) {
      return (host!, port!);
    }
    return null;
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
