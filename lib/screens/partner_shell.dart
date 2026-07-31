import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/foreground_sync_service.dart';
import '../services/sync_client.dart';
import '../theme/lyris_theme.dart';
import '../widgets/partner_calendar.dart';

/// Full-screen shell for partner mode.
/// Flow: pair via QR (once) → auto-sync over WiFi → read-only view.
class PartnerShell extends StatefulWidget {
  PartnerShell({super.key});

  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  Map<String, dynamic>? _partnerData;
  bool _loading = true;
  bool _syncing = false;
  String? _syncStatus; // null = idle, otherwise message
  final LyrisSyncClient _syncClient = LyrisSyncClient();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _syncClient.stopDiscovery();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('partner_data');
    if (saved != null) {
      // The cache is stored as authenticated ciphertext; decrypt in-memory
      // only for display. Falls back to null (→ re-pair) if the token was
      // rotated or the cache is from an older plaintext build.
      _partnerData = await LyrisSyncClient.decryptEnvelope(saved);
    }
    if (mounted) setState(() => _loading = false);

    // If paired, try auto-sync immediately + start background service
    final token = await LyrisSyncClient.getAuthToken();
    if (token != null) {
      _tryAutoSync();
      LyrisForegroundService.startPartner();
    }
  }

  void _tryAutoSync() {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _syncStatus = 'Looking for Lyris on your network…';
    });

    // Safety timeout: reset UI after 35s regardless
    Future.delayed(Duration(seconds: 35), () {
      if (mounted && _syncing) {
        setState(() {
          _syncing = false;
          _syncStatus = null;
        });
        _syncClient.stopDiscovery();
      }
    });

    _syncClient.startDiscovery(
      onData: (data, envelopeJson) async {
        await _savePartnerData(data, envelopeJson);
        if (mounted) {
          setState(() {
            _syncing = false;
            _syncStatus = null;
          });
        }
        _syncClient.stopDiscovery();
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _syncing = false;
            _syncStatus = null;
          });
        }
        _syncClient.stopDiscovery();
      },
      onServerFound: () {
        if (mounted) {
          setState(() => _syncStatus = 'Found Lyris! Syncing…');
        }
      },
    );
  }

  /// Cache partner data encrypted at rest.
  ///
  /// [envelopeJson] is the raw authenticated-ciphertext envelope from a WiFi
  /// sync — stored verbatim. When null (QR pairing path), [data] arrives as
  /// plaintext and is encrypted here; the `authToken` field is stripped first
  /// because it already lives in the keystore and must not be duplicated in
  /// the cache.
  Future<void> _savePartnerData(Map<String, dynamic> data, [String? envelopeJson]) async {
    final prefs = await SharedPreferences.getInstance();
    String toStore;
    if (envelopeJson != null) {
      toStore = envelopeJson;
    } else {
      final cacheData = Map<String, dynamic>.from(data)..remove('authToken');
      final encrypted = await LyrisSyncClient.encryptEnvelope(cacheData);
      if (encrypted == null) return; // not paired — nothing to cache
      toStore = encrypted;
    }
    await prefs.setString('partner_data', toStore);
    if (mounted) setState(() => _partnerData = data);
  }

  Future<void> _switchToTracker() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('partner_mode', 'owner');
    await prefs.setString('user_role', 'tracker');
    await prefs.remove('partner_data');
    AppEntry.roleChanged.value++;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_partnerData == null) {
      return _PairScreen(onPaired: _savePartnerData);
    }

    return _PartnerHome(
      data: _partnerData!,
      syncing: _syncing,
      syncStatus: _syncStatus,
      onRefresh: _tryAutoSync,
      onReScan: () async {
        // Clear data and go back to pairing
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('partner_data');
        if (mounted) setState(() => _partnerData = null);
      },
      onSwitchToTracker: _switchToTracker,
    );
  }
}

// ─── Pair Screen (QR Scanner) ─────────────────────────────────────────────

class _PairScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> data) onPaired;

  const _PairScreen({required this.onPaired});

  @override
  State<_PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<_PairScreen> {
  bool _scanning = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _scanning ? _buildScanner() : _buildLanding(),
      ),
    );
  }

  Widget _buildLanding() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: LyrisTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Icon(Icons.visibility_rounded, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4)),
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Partner Mode',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Scan your partner\'s Lyris QR code to connect. After pairing, data syncs automatically when you\'re on the same WiFi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),
          SizedBox(height: 48),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LyrisTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: LyrisTheme.error, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() {
                _scanning = true;
                _error = null;
              }),
              icon: Icon(Icons.qr_code_scanner_rounded),
              label: Text('Scan Pairing Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _showManualInput,
            icon: Icon(Icons.paste_rounded),
            label: Text('Paste Code Manually'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              side: BorderSide(color: Theme.of(context).dividerColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          SizedBox(height: 48),

          GestureDetector(
            onTap: _confirmSwitchToTracker,
            child: Text(
              'Actually, I want to track my own cycle →',
              style: TextStyle(
                fontSize: 13,
                color: LyrisTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _scanning = false),
                icon: Icon(Icons.arrow_back_rounded),
              ),
              SizedBox(width: 8),
              Text(
                'Scan Pairing Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: MobileScanner(
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final code = barcodes.first.rawValue;
                    if (code != null) _parseQrData(code);
                  }
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Point your camera at your partner\'s Lyris QR code',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _parseQrData(String raw) {
    try {
      String jsonStr;
      if (raw.startsWith('LYRIS:')) {
        final encoded = raw.substring(5);
        jsonStr = utf8.decode(base64Url.decode(base64Url.normalize(encoded)));
      } else {
        jsonStr = raw;
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      if (data['type'] != 'lyris_share') {
        setState(() {
          _error = 'This is not a Lyris Tracker QR code.';
          _scanning = false;
        });
        return;
      }

      // Save auth token for future WiFi sync
      final authToken = data['authToken'] as String?;
      if (authToken != null) {
        LyrisSyncClient.savePairing(authToken);
      }

      widget.onPaired(data);
    } catch (e) {
      setState(() {
        _error = 'Could not read this code. Make sure it\'s from Lyris Tracker.';
        _scanning = false;
      });
    }
  }

  void _showManualInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Paste Share Code', style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'LYRIS:...',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _parseQrData(controller.text.trim());
            },
            child: Text('Load'),
          ),
        ],
      ),
    );
  }

  void _confirmSwitchToTracker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Switch to Tracker?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('You\'ll get the full tracking app with calendar, predictions, and insights.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('partner_mode', 'owner');
              await prefs.setString('user_role', 'tracker');
              await prefs.remove('partner_data'); // clear partner data
              AppEntry.roleChanged.value++;
            },
            child: Text('Switch'),
          ),
        ],
      ),
    );
  }
}

// ─── Partner Home (Read-Only + Auto-Sync) ─────────────────────────────────

class _PartnerHome extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool syncing;
  final String? syncStatus;
  final VoidCallback onRefresh;
  final VoidCallback onReScan;
  final VoidCallback onSwitchToTracker;

  const _PartnerHome({
    required this.data,
    required this.syncing,
    required this.syncStatus,
    required this.onRefresh,
    required this.onReScan,
    required this.onSwitchToTracker,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d. MMM');
    final phaseName = data['phase'] as String? ?? 'follicular';
    final phaseLabel = data['phaseLabel'] as String? ?? 'Follicular';
    final phaseEmoji = data['phaseEmoji'] as String? ?? '🌱';
    final cycleDay = data['cycleDay'] as int?;
    final cycleLength = data['cycleLength'] as int?;
    final phaseColor = LyrisTheme.phaseColor(phaseName);

    DateTime? parseDate(String? key) {
      final v = data[key] as String?;
      return v != null ? DateTime.tryParse(v) : null;
    }

    final nextPeriod = parseDate('nextPeriod');
    final ovulation = parseDate('ovulation');
    final fertileStart = parseDate('fertileStart');
    final fertileEnd = parseDate('fertileEnd');
    final pmsStart = parseDate('pmsStart');
    final sharedAt = parseDate('sharedAt');
    final syncedAt = parseDate('syncedAt');

    // Days until next period
    String? daysUntil;
    if (nextPeriod != null) {
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final target = DateTime(nextPeriod.year, nextPeriod.month, nextPeriod.day);
      final diff = target.difference(today).inDays;
      if (diff > 0) daysUntil = 'in $diff days';
      else if (diff == 0) daysUntil = 'today';
      else daysUntil = '${-diff} days ago';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lyris',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) {
                        if (value == 'refresh') onRefresh();
                        if (value == 'rescan') onReScan();
                        if (value == 'switch') onSwitchToTracker();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'refresh', child: Text('Sync Now')),
                        PopupMenuItem(value: 'rescan', child: Text('Re-pair (new QR)')),
                        PopupMenuItem(value: 'switch', child: Text('Switch to Tracker')),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Sync status bar
            if (syncing || syncStatus != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: LyrisTheme.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: LyrisTheme.info,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            syncStatus ?? 'Syncing…',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: LyrisTheme.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Phase hero
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [phaseColor.withOpacity(0.15), phaseColor.withOpacity(0.04)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: phaseColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(phaseEmoji, style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text(
                        phaseLabel,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: phaseColor,
                        ),
                      ),
                      if (cycleDay != null) ...[
                        SizedBox(height: 6),
                        Text(
                          'Cycle Day $cycleDay${cycleLength != null ? ' / ~$cycleLength' : ''}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      SizedBox(height: 10),
                      Text(
                        syncedAt != null
                            ? 'Auto-synced ${DateFormat('d. MMM, HH:mm').format(syncedAt)}'
                            : sharedAt != null
                                ? 'Shared ${DateFormat('d. MMM, HH:mm').format(sharedAt)}'
                                : '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Predictions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Upcoming',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12)),

            if (nextPeriod != null)
              SliverToBoxAdapter(
                child: _PredictionCard(
                  icon: Icons.water_drop_rounded,
                  label: 'Next Period',
                  value: dateFormat.format(nextPeriod),
                  sub: daysUntil,
                  color: LyrisTheme.periodColor,
                ),
              ),
            if (ovulation != null)
              SliverToBoxAdapter(
                child: _PredictionCard(
                  icon: Icons.brightness_high_rounded,
                  label: 'Ovulation',
                  value: dateFormat.format(ovulation),
                  color: LyrisTheme.ovulationColor,
                ),
              ),
            if (fertileStart != null && fertileEnd != null)
              SliverToBoxAdapter(
                child: _PredictionCard(
                  icon: Icons.eco_rounded,
                  label: 'Fertile Window',
                  value: '${dateFormat.format(fertileStart)} – ${dateFormat.format(fertileEnd)}',
                  color: LyrisTheme.fertileColor,
                ),
              ),
            if (pmsStart != null)
              SliverToBoxAdapter(
                child: _PredictionCard(
                  icon: Icons.waves_rounded,
                  label: 'PMS likely from',
                  value: dateFormat.format(pmsStart),
                  color: LyrisTheme.pmsColor,
                ),
              ),

            // ── Read-only Calendar ──
            SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Calendar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PartnerCalendar(
                  periodDates: _parsePeriodDates(data),
                  nextPeriod: nextPeriod,
                  predictedPeriodLength: (data['periodLength'] as num?)?.toInt() ?? 5,
                  ovulation: ovulation,
                  fertileStart: fertileStart,
                  fertileEnd: fertileEnd,
                ),
              ),
            ),

            // Footer
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          SizedBox(width: 6),
                          Text(
                            'Read-only view',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Syncs automatically when both devices are on the same WiFi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sub;
  final Color color;

  const _PredictionCard({
    required this.icon,
    required this.label,
    required this.value,
    this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Icon(icon, size: 22, color: color)),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Parse period date strings ("2026-07-15") from sync data into DateTime set.
Set<DateTime> _parsePeriodDates(Map<String, dynamic> data) {
  final raw = data['periodDates'];
  if (raw is! List) return {};
  final dates = <DateTime>{};
  for (final s in raw) {
    if (s is String) {
      final parts = s.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          dates.add(DateTime(y, m, d));
        }
      }
    }
  }
  return dates;
}
