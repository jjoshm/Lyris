import 'package:flutter/material.dart';

import '../services/prediction_engine.dart';
import '../theme/lyris_theme.dart';

/// Shows current cycle phase info with helpful context
class PhaseCard extends StatelessWidget {
  final CyclePhase phase;
  final int? cycleDay;

  PhaseCard({super.key, required this.phase, this.cycleDay});

  @override
  Widget build(BuildContext context) {
    final color = LyrisTheme.phaseColor(phase.name);
    final info = _phaseInfo(phase);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(phase.emoji, style: TextStyle(fontSize: 24)),
              SizedBox(width: 8),
              Text(
                phase.label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            info,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _phaseInfo(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.period:
        return 'Your period is here. Be gentle with yourself — rest, hydrate, and use a heating pad if needed.';
      case CyclePhase.follicular:
        return 'Estrogen is rising. Energy increases, skin clears up, and you may feel more social and creative.';
      case CyclePhase.fertile:
        return 'You\'re in your fertile window. Cervical mucus may be clear and stretchy. Libido often peaks.';
      case CyclePhase.ovulation:
        return 'Ovulation day! An egg is released. Some feel a slight twinge on one side (Mittelschmerz).';
      case CyclePhase.pms:
        return 'Progesterone drops. You may notice mood shifts, bloating, or cravings. Self-care is key.';
    }
  }
}
