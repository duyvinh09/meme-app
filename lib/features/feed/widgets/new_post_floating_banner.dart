import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/localization_extension.dart';

class NewPostFloatingBanner extends StatelessWidget {
  final int newPostsCount;
  final VoidCallback onTap;

  const NewPostFloatingBanner({
    super.key,
    required this.newPostsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = newPostsCount > 0;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      offset: isVisible ? Offset.zero : const Offset(0, -1.2),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isVisible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.mediumImpact();
                onTap();
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB800),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Upward Arrow inside Black Circle Badge
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Color(0xFFFFB800),
                          size: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Text
                    Text(
                      newPostsCount <= 1
                          ? context.l10n.oneNewPost
                          : context.l10n.newPostsCount(newPostsCount),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
