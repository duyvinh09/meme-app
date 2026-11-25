import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../models/photobooth_frame.dart';

class PhotoboothFramePicker extends StatefulWidget {
  /// Fraction of screen height occupied by the photobooth sheet.
  static const heightFraction = 0.75;

  const PhotoboothFramePicker({this.selected, super.key});
  final PhotoboothFrame? selected;

  @override
  State<PhotoboothFramePicker> createState() => _PhotoboothFramePickerState();
}

class _PhotoboothFramePickerState extends State<PhotoboothFramePicker> {
  late Future<List<PhotoboothFrame>> _catalog;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _catalog = PhotoboothFrame.loadCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: AppColors.card(context),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height *
              PhotoboothFramePicker.heightFraction,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.filter_frames_outlined,
                    color: AppColors.primaryBlue, size: 22),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(l10n.photobooth,
                        style: AppTextStyles.sectionTitle(context))),
                if (widget.selected != null)
                  IconButton(
                    onPressed: () => Navigator.pop(context, widget.selected),
                    icon: Icon(Icons.restart_alt_rounded,
                        size: 21, semanticLabel: l10n.photoboothReset),
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      size: 21, semanticLabel: l10n.cancel),
                ),
              ]),
              const SizedBox(height: 4),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: List.generate(
                        5,
                        (index) => Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: ChoiceChip(
                                showCheckmark: false,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                labelPadding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                visualDensity: VisualDensity.compact,
                                label: Text(index == 0
                                    ? l10n.photoboothAll
                                    : l10n.photoboothGroup(index)),
                                labelStyle:
                                    AppTextStyles.caption(context).copyWith(
                                  color: _count == index
                                      ? AppColors.textPrimary(context)
                                      : AppColors.textSecondary(context),
                                  fontWeight: _count == index
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                                selected: _count == index,
                                selectedColor: AppColors.primaryBlue
                                    .withValues(alpha: 0.22),
                                backgroundColor: AppColors.surface(context),
                                side: BorderSide(
                                    color: _count == index
                                        ? AppColors.primaryBlue
                                        : AppColors.border(context)),
                                onSelected: (_) =>
                                    setState(() => _count = index),
                              ),
                            ))),
              ),
              const SizedBox(height: 4),
              Expanded(
                  child: FutureBuilder<List<PhotoboothFrame>>(
                future: _catalog,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                        child: TextButton(
                      onPressed: () => setState(() {
                        _catalog = PhotoboothFrame.loadCatalog();
                      }),
                      child: Text(l10n.photoboothLoadError,
                          style: Theme.of(context).textTheme.labelLarge),
                    ));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final frames = snapshot.data!
                      .where(
                          (frame) => _count == 0 || frame.shotCount == _count)
                      .toList();
                  if (frames.isEmpty) {
                    return Center(
                        child: Text(l10n.photoboothEmpty,
                            style: AppTextStyles.bodySecondary(context)));
                  }
                  return _ThemedFrameList(
                      frames: frames, selected: widget.selected);
                },
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

class _ThemedFrameList extends StatelessWidget {
  const _ThemedFrameList({required this.frames, required this.selected});
  final List<PhotoboothFrame> frames;
  final PhotoboothFrame? selected;

  @override
  Widget build(BuildContext context) {
    final sections = <PhotoboothTheme, List<PhotoboothFrame>>{
      for (final theme in PhotoboothTheme.values)
        theme: frames.where((frame) => frame.theme == theme).toList(),
    };
    return CustomScrollView(slivers: [
      for (final entry
          in sections.entries.where((entry) => entry.value.isNotEmpty)) ...[
        SliverPadding(
          padding: const EdgeInsetsDirectional.only(top: 12, bottom: 10),
          sliver: SliverToBoxAdapter(
              child:
                  _ThemeHeading(theme: entry.key, count: entry.value.length)),
        ),
        SliverLayoutBuilder(builder: (context, constraints) {
          final columns =
              (constraints.crossAxisExtent / 142).ceil().clamp(1, 20);
          final width =
              (constraints.crossAxisExtent - (columns - 1) * 10) / columns;
          final captionHeight =
              MediaQuery.textScalerOf(context).scale(11) * 1.3;
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisExtent: width + captionHeight + 10,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _FrameTile(
                key: ValueKey(entry.value[index].id),
                frame: entry.value[index],
                selected: entry.value[index].id == selected?.id,
              ),
              childCount: entry.value.length,
            ),
          );
        }),
      ],
      const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
    ]);
  }
}

class _ThemeHeading extends StatelessWidget {
  const _ThemeHeading({required this.theme, required this.count});
  final PhotoboothTheme theme;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (theme) {
      PhotoboothTheme.film => l10n.photoboothThemeFilm,
      PhotoboothTheme.cute => l10n.photoboothThemeCute,
      PhotoboothTheme.love => l10n.photoboothThemeLove,
      PhotoboothTheme.celebration => l10n.photoboothThemeCelebration,
      PhotoboothTheme.personality => l10n.photoboothThemePersonality,
      PhotoboothTheme.comments => l10n.photoboothThemeComments,
    };
    return Semantics(
        header: true,
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: AppTextStyles.body(context)
                      .copyWith(fontWeight: FontWeight.w800))),
          Text(l10n.photoboothFrameCount(count),
              style: AppTextStyles.caption(context)),
        ]));
  }
}

class _FrameTile extends StatelessWidget {
  const _FrameTile({required this.frame, required this.selected, super.key});
  final PhotoboothFrame frame;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: frame.name,
      child: InkWell(
        onTap: () => Navigator.pop(context, frame),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
            border: Border.all(
                color: selected
                    ? AppColors.primaryBlue
                    : AppColors.border(context),
                width: selected ? 2 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.asset(
                  frame.thumbnail,
                  fit: BoxFit.contain,
                  cacheWidth: 240,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: 6),
              Row(children: [
                if (selected) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primaryBlue, size: 13),
                  const SizedBox(width: 3),
                ],
                Expanded(
                    child: Text(
                  frame.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption(context).copyWith(fontSize: 11),
                )),
                const SizedBox(width: 3),
                Text('${frame.shotCount}',
                    style:
                        AppTextStyles.caption(context).copyWith(fontSize: 9)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
