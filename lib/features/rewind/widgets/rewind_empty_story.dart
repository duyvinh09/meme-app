import 'package:flutter/material.dart';

import '../../../core/extensions/localization_extension.dart';
import '../models/rewind_period.dart';

class RewindEmptyStory extends StatelessWidget {
  final RewindPeriod period;
  final VoidCallback onPickPeriod;

  const RewindEmptyStory({
    super.key,
    required this.period,
    required this.onPickPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: Text(
                '🌱',
                style: TextStyle(fontSize: 44),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            l10n.rewindEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            l10n.rewindEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 28),

          OutlinedButton.icon(
            onPressed: onPickPeriod,
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
            label: Text(
              l10n.rewindSelectPeriod,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
