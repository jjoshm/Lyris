import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/cycle_providers.dart';
import '../services/sync_server.dart';
import '../theme/lyris_theme.dart';

/// Tracker-side Partner Screen.
/// - Generate pairing QR code (contains auth token)
/// - Toggle WiFi auto-sync (mDNS broadcast + HTTP server)
class PartnerScreen extends ConsumerStatefulWidget {
  PartnerScreen({super.key});

  @override
  ConsumerState<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends ConsumerState<PartnerScreen> {
  String? _qrData;
  bool _wifiSharing = false;
  bool _startingServer = false;
  final LyrisSyncServer _syncServer = LyrisSyncServer.instance;

  @override
  void initState() {
    super.initState();
    _wifiSharing = _syncServer.isRunning;
    // Register data provider so the singleton can serve fresh data
    _syncServer.setDataProvider(_buildShareData);
  }

  @override
  void dispose() {
    // Don't stop server on dispose — it should keep running in background
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Partner Sharing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── WiFi Auto-Sync Section ──
            _SectionHeader(
              icon: Icons.wifi_rounded,
              title: 'WiFi Auto-Sync',
              subtitle: 'Partner gets updates automatically when both on same WiFi',
            ),
            SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _wifiSharing
                      ? LyrisTheme.success.withOpacity(0.3)
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (_wifiSharing ? LyrisTheme.success : Theme.of(context).colorScheme.onSurfaceVariant)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _wifiSharing ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: _wifiSharing ? LyrisTheme.success : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _wifiSharing ? 'Sharing active' : 'Sharing off',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _wifiSharing
                              ? 'Broadcasting on local network'
                              : 'Partner must scan QR manually',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _wifiSharing,
                    onChanged: _startingServer ? null : _toggleWifiSharing,
                    activeColor: LyrisTheme.success,
                  ),
                ],
              ),
            ),

            if (_wifiSharing) ...[
              SizedBox(height: 8),
            ],

            SizedBox(height: 32),

            // ── Pairing QR Code Section ──
            _SectionHeader(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Pairing Code',
              subtitle: 'Partner scans this once to connect (includes auth key)',
            ),
            SizedBox(height: 12),

            if (_qrData != null) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: _qrData!,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: LyrisTheme.primary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  'Let your partner scan this code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  'Generated ${DateFormat('HH:mm').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _rotateAndGenerateQr,
                  icon: Icon(Icons.refresh_rounded),
                  label: Text('New Pairing Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LyrisTheme.primary,
                    side: BorderSide(color: LyrisTheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateQrCode,
                  icon: Icon(Icons.qr_code_2_rounded),
                  label: Text('Generate Pairing Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],

            SizedBox(height: 32),

            // ── Privacy note ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LyrisTheme.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LyrisTheme.success.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, color: LyrisTheme.success, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All data stays on your local network. Nothing goes through the internet. Partner sees predictions and phase only — not individual symptom entries. Auth token required for access.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleWifiSharing(bool value) async {
    if (value) {
      setState(() => _startingServer = true);
      try {
        await _syncServer.start(dataProvider: _buildShareData);
        setState(() {
          _wifiSharing = true;
          _startingServer = false;
        });
      } catch (e) {
        setState(() => _startingServer = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not start sharing: $e'),
              backgroundColor: LyrisTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      await _syncServer.stop();
      setState(() => _wifiSharing = false);
    }
  }

  Future<void> _generateQrCode() async {
    final authToken = await LyrisSyncServer.getAuthToken();
    _buildQrWithToken(authToken);
  }

  /// Rotate the token and show a fresh QR. Invalidates the old pairing —
  /// the partner must re-scan.
  Future<void> _rotateAndGenerateQr() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('New Pairing Code?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'This invalidates the current code. Your partner will need to scan '
          'the new one to keep syncing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Generate New Code'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final authToken = await LyrisSyncServer.rotateToken();
    _buildQrWithToken(authToken);
  }

  void _buildQrWithToken(String authToken) {
    final shareData = _buildShareData();
    shareData['authToken'] = authToken;
    shareData['syncPort'] = LyrisSyncServer.port;

    final jsonStr = jsonEncode(shareData);
    final encoded = base64UrlEncode(utf8.encode(jsonStr));

    setState(() {
      _qrData = 'LYRIS:$encoded';
    });
  }

  Map<String, dynamic> _buildShareData() {
    final prediction = ref.read(predictionProvider);
    final phase = ref.read(currentPhaseProvider);
    final cycleDay = ref.read(currentCycleDayProvider);

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
      'sharedAt': DateTime.now().toIso8601String(),
    };
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: LyrisTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: LyrisTheme.primary),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
