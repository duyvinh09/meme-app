import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../controllers/photobooth_controller.dart';
import '../services/photobooth_canvas.dart';

class PhotoboothButton extends StatelessWidget {
  const PhotoboothButton({
    required this.controller,
    required this.onPressed,
    required this.onClear,
    this.size = 72,
    super.key,
  });
  final PhotoboothController controller;
  final VoidCallback? onPressed;
  final VoidCallback onClear;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final frame = controller.frame;
        final l10n = context.l10n;
        if (frame == null) {
          return IconButton.filledTonal(
            onPressed: onPressed,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.45),
              foregroundColor: Colors.white,
              fixedSize: const Size(38, 38),
              minimumSize: const Size(38, 38),
              visualDensity: VisualDensity.standard,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(CupertinoIcons.film,
                size: 20, semanticLabel: l10n.photobooth),
          );
        }
        final progress =
            l10n.photoboothProgress(controller.capturedCount, frame.shotCount);
        return SizedBox.square(
          dimension: size,
          child: Stack(children: [
            Positioned.fill(
              child: Semantics(
                button: true,
                label: '${l10n.photobooth}: ${frame.name}, $progress',
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border:
                          Border.all(color: AppColors.primaryBlue, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(fit: StackFit.expand, children: [
                          RepaintBoundary(
                              child: CustomPaint(
                            painter: PhotoboothCanvasPainter(PhotoboothScene(
                              frame: frame,
                              shots: controller.shots,
                              artwork: controller.artwork,
                            )),
                          )),
                          if (controller.artwork == null)
                            Image.asset(frame.thumbnail,
                                fit: BoxFit.cover, excludeFromSemantics: true),
                          for (var i = controller.capturedCount;
                              i < frame.shotCount;
                              i++)
                            Positioned(
                              left:
                                  frame.slots[i].center.dx / 1080 * (size - 3) -
                                      6,
                              top:
                                  frame.slots[i].center.dy / 1080 * (size - 3) -
                                      6,
                              child: ExcludeSemantics(
                                  child: Container(
                                width: 12,
                                height: 12,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: i == controller.capturedCount
                                      ? AppColors.primaryBlue
                                      : Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        height: 1)),
                              )),
                            ),
                          PositionedDirectional(
                              bottom: 0,
                              end: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 1),
                                color: Colors.black.withValues(alpha: 0.65),
                                child: Text(progress,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 8)),
                              )),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
                top: 4,
                end: 4,
                child: SizedBox.square(
                  dimension: 28,
                  child: IconButton(
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    icon: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: AppColors.card(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border(context)),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 12,
                          color: AppColors.textPrimary(context),
                          semanticLabel: l10n.photoboothOff),
                    ),
                  ),
                )),
          ]),
        );
      },
    );
  }
}
