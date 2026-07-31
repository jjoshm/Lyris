import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../providers/cycle_providers.dart';
import '../providers/theme_provider.dart';
import '../theme/lyris_theme.dart';
import '../widgets/lyris_icons.dart';
import 'partner_screen.dart';

/// Settings — reminders, data management, about
class SettingsScreen extends ConsumerStatefulWidget {
  SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _remindersEnabled = false;
  String _reminderTime = '09:00';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersEnabled = prefs.getBool('reminders_enabled') ?? false;
      _reminderTime = prefs.getString('reminder_time') ?? '09:00';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Partner Mode
          _SectionHeader(title: 'Partner Mode'),
          _SettingsTile(
            icon: Icons.favorite_rounded,
            color: LyrisTheme.primary,
            title: 'Share with Partner',
            subtitle: 'Pairing code & WiFi auto-sync',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PartnerScreen()),
            ),
          ),
          SizedBox(height: 1),
          _SettingsTile(
            icon: Icons.swap_horiz_rounded,
            color: LyrisTheme.info,
            title: 'Switch to Partner Mode',
            subtitle: 'View someone else\'s cycle (read-only)',
            onTap: _confirmSwitchToPartner,
          ),

          SizedBox(height: 24),

          // Appearance
          _SectionHeader(title: 'Appearance'),
          _ThemeToggle(),

          SizedBox(height: 24),

          // Reminders
          _SectionHeader(title: 'Reminders'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Daily Log Reminder',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Remind me to log symptoms',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  value: _remindersEnabled,
                  activeColor: LyrisTheme.primary,
                  onChanged: (v) async {
                    setState(() => _remindersEnabled = v);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('reminders_enabled', v);
                  },
                ),
                if (_remindersEnabled)
                  ListTile(
                    title: Text(
                      'Reminder Time',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: Text(
                      _reminderTime,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: LyrisTheme.primary,
                      ),
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: int.parse(_reminderTime.split(':')[0]),
                          minute: int.parse(_reminderTime.split(':')[1]),
                        ),
                      );
                      if (time != null) {
                        final formatted =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        setState(() => _reminderTime = formatted);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('reminder_time', formatted);
                      }
                    },
                  ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Data
          _SectionHeader(title: 'Data'),
          _SettingsTile(
            icon: Icons.download_rounded,
            color: LyrisTheme.success,
            title: 'Export Data',
            subtitle: 'Save as JSON file',
            onTap: _exportData,
          ),
          SizedBox(height: 1),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            color: LyrisTheme.error,
            title: 'Delete All Data',
            subtitle: 'Permanently erase everything',
            onTap: _confirmDeleteAll,
          ),

          SizedBox(height: 24),

          // About
          _SectionHeader(title: 'About'),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                LyrisIcons.logo(size: 36, color: LyrisTheme.primary),
                SizedBox(height: 8),
                Text(
                  'Lyris Tracker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '100% offline. Your data never leaves your device.\nNo accounts. No tracking. No ads. Free forever.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 100),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    final db = ref.read(databaseProvider);
    final data = await db.exportAllData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Export ready: ${data['periods']?.length ?? 0} period entries, '
            '${data['symptoms']?.length ?? 0} symptom entries',
          ),
          backgroundColor: LyrisTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _confirmSwitchToPartner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Switch to Partner Mode?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'You\'ll switch to the read-only partner view. Your tracking data stays saved and you can switch back anytime.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('partner_mode', 'partner');
      await prefs.remove('partner_data'); // clear stale partner data
      AppEntry.roleChanged.value++;
    }
  }

  Future<void> _confirmDeleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete All Data?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'This will permanently erase all period logs, symptoms, and settings. This cannot be undone.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: LyrisTheme.error),
            child: Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.deleteAllData();
      // Invalidate all providers so UI refreshes immediately
      ref.invalidate(allPeriodEntriesProvider);
      ref.invalidate(cyclesProvider);
      ref.invalidate(predictionProvider);
      ref.invalidate(currentPhaseProvider);
      ref.invalidate(currentCycleDayProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All data deleted'),
            backgroundColor: LyrisTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme mode selector — Light / Dark / System
class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: LyrisTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LyrisIcons.darkMode, color: LyrisTheme.primary, size: 20),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Theme',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            // Segmented control
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: LyrisThemeMode.values.map((mode) {
                  final isSelected = currentMode == mode;
                  IconData icon;
                  switch (mode) {
                    case LyrisThemeMode.light:
                      icon = LyrisIcons.lightMode;
                      break;
                    case LyrisThemeMode.dark:
                      icon = LyrisIcons.darkMode;
                      break;
                    case LyrisThemeMode.system:
                      icon = LyrisIcons.systemMode;
                      break;
                  }
                  return GestureDetector(
                    onTap: () => ref.read(themeProvider.notifier).setMode(mode),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? LyrisTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
