import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/cycle_models.dart';
import '../providers/cycle_providers.dart';
import '../theme/lyris_theme.dart';
import '../widgets/cycle_ring.dart';
import '../widgets/phase_card.dart';
import '../widgets/prediction_card.dart';
import 'log_period_screen.dart';
import 'log_symptoms_screen.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prediction = ref.watch(predictionProvider);
    final phase = ref.watch(currentPhaseProvider);
    final cycleDay = ref.watch(currentCycleDayProvider);
    final cycles = ref.watch(cyclesProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lyris',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: LyrisTheme.primary,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, MMM d').format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cycle Ring
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: CycleRing(
                  cycleDay: cycleDay,
                  cycleLength: prediction?.predictedCycleLength ?? 28,
                  phase: phase,
                ),
              ),
            ),

            // Phase Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: PhaseCard(phase: phase, cycleDay: cycleDay),
              ),
            ),

            // Prediction Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: PredictionCard(prediction: prediction),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Quick Log',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.water_drop_rounded,
                        label: 'Period',
                        color: LyrisTheme.periodColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LogPeriodScreen()),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionTile(
                        icon: Icons.emoji_emotions_rounded,
                        label: 'Symptoms',
                        color: LyrisTheme.fertileColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LogSymptomsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Cycle History Summary
            if (cycles.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: _CycleSummaryCard(cycles: cycles),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CycleSummaryCard extends StatelessWidget {
  final List<CycleData> cycles;

  const _CycleSummaryCard({required this.cycles});

  @override
  Widget build(BuildContext context) {
    final completedCycles = cycles.where((c) => c.cycleLength != null).toList();
    if (completedCycles.isEmpty) return const SizedBox.shrink();

    final avgLength = (completedCycles
                .map((c) => c.cycleLength!)
                .reduce((a, b) => a + b) /
            completedCycles.length)
        .round();

    final avgPeriod = completedCycles
            .where((c) => c.periodLength != null)
            .isNotEmpty
        ? (completedCycles
                    .where((c) => c.periodLength != null)
                    .map((c) => c.periodLength!)
                    .reduce((a, b) => a + b) /
                completedCycles.where((c) => c.periodLength != null).length)
            .round()
        : 5;

    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Averages',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _StatChip(label: 'Cycle', value: '$avgLength days', color: LyrisTheme.primary),
              SizedBox(width: 12),
              _StatChip(label: 'Period', value: '$avgPeriod days', color: LyrisTheme.periodColor),
              SizedBox(width: 12),
              _StatChip(
                label: 'Cycles',
                value: '${completedCycles.length}',
                color: LyrisTheme.fertileColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
