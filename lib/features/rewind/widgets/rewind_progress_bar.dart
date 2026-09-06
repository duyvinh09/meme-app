import 'package:flutter/material.dart';

class RewindProgressBar extends StatelessWidget {
  final int totalSegments;
  final int currentIndex;
  final double currentProgress; // 0.0 to 1.0

  const RewindProgressBar({
    super.key,
    required this.totalSegments,
    required this.currentIndex,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSegments <= 0) return const SizedBox.shrink();

    return Row(
      children: List.generate(totalSegments, (index) {
        double segmentProgress = 0.0;
        if (index < currentIndex) {
          segmentProgress = 1.0;
        } else if (index == currentIndex) {
          segmentProgress = currentProgress.clamp(0.0, 1.0);
        } else {
          segmentProgress = 0.0;
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 3.5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: segmentProgress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
