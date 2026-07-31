import 'package:flutter/material.dart';

import '../theme/lyris_theme.dart';
import '../screens/log_period_screen.dart';

/// Floating action button for quick logging
class LogFab extends StatelessWidget {
  const LogFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LogPeriodScreen()),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Log'),
      backgroundColor: LyrisTheme.primary,
      foregroundColor: Colors.white,
    );
  }
}
