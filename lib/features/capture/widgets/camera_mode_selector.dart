import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/localization_extension.dart';
import '../models/camera_capture_mode.dart';

class CameraModeSelector extends StatelessWidget {
  const CameraModeSelector(
      {required this.mode,
      required this.accent,
      required this.border,
      required this.onChanged,
      this.enabled = true,
      this.allowBill = true,
      super.key});
  final CameraCaptureMode mode;
  final Color accent;
  final Color border;
  final ValueChanged<CameraCaptureMode> onChanged;
  final bool enabled;
  final bool allowBill;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final item in CameraCaptureMode.values)
          if (allowBill || item != CameraCaptureMode.bill)
            Semantics(
              button: true,
              selected: mode == item,
              enabled: enabled,
              label: switch (item) {
                CameraCaptureMode.photo => l10n.receiptPhotoMode,
                CameraCaptureMode.bill => l10n.receiptBillMode,
                CameraCaptureMode.video => l10n.receiptVideoMode,
              },
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: enabled ? () => onChanged(item) : null,
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mode == item ? accent : Colors.transparent),
                      child: ExcludeSemantics(
                          child: Icon(
                              switch (item) {
                                CameraCaptureMode.photo =>
                                  CupertinoIcons.camera_fill,
                                CameraCaptureMode.bill =>
                                  CupertinoIcons.doc_text_viewfinder,
                                CameraCaptureMode.video =>
                                  CupertinoIcons.videocam_fill,
                              },
                              size: 19,
                              color: Colors.white
                                  .withValues(alpha: mode == item ? 1 : 0.75))),
                    ),
                  )),
            ),
      ]),
    );
  }
}
