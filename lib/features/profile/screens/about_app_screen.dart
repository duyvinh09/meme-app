import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';
import '../../../core/utils/app_haptics.dart';
import '../widgets/development_team_section.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsetsDirectional.only(start: 16, end: 12),
          child: Center(child: _AboutBackButton()),
        ),
        titleSpacing: 0,
        title: Text(l10n.aboutMeme,
            style: AppTextStyles.pageTitle(context)
                .copyWith(fontSize: 22, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _ThankYouCard(),
                            const SizedBox(height: 32),
                            const DevelopmentTeamSection(),
                            const SizedBox(height: 32),
                            Semantics(
                                header: true,
                                child: Text(l10n.memeProject,
                                    style:
                                        AppTextStyles.sectionTitle(context))),
                            const SizedBox(height: 14),
                            _ProjectLinkCard(
                                icon: Icons.download_outlined,
                                title: l10n.memeReleases,
                                subtitle: l10n.memeReleasesDescription,
                                path: '/duyvinh09/meme-app/releases'),
                            const SizedBox(height: 12),
                            _ProjectLinkCard(
                                icon: Icons.star_rounded,
                                highlighted: true,
                                title: l10n.memeStarRepo,
                                subtitle: l10n.memeStarRepoDescription,
                                path: '/duyvinh09/meme-app'),
                            const SizedBox(height: 12),
                          ])),
                )),
          )),
    );
  }
}

class _AboutBackButton extends StatelessWidget {
  const _AboutBackButton();

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: MaterialLocalizations.of(context).backButtonTooltip,
        child: SizedBox.square(
          dimension: 44,
          child: Material(
            color: AppColors.card(context),
            shape: CircleBorder(
                side: BorderSide(color: AppColors.border(context))),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.pop(context);
              },
              child: ExcludeSemantics(
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 19, color: AppColors.textPrimary(context))),
            ),
          ),
        ),
      );
}

class _ThankYouCard extends StatelessWidget {
  const _ThankYouCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [
              colors.primary.withValues(alpha: 0.14),
              AppColors.primaryPink.withValues(alpha: 0.08),
            ]),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          child: Column(children: [
            const _ThankYouHeart(),
            const SizedBox(height: 20),
            Semantics(
                header: true,
                child: Text(l10n.memeThankYouTitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageTitle(context))),
            const SizedBox(height: 14),
            Text(l10n.memeThankYouMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary(context)),
          ])),
    );
  }
}

class _ThankYouHeart extends StatefulWidget {
  const _ThankYouHeart();

  @override
  State<_ThankYouHeart> createState() => _ThankYouHeartState();
}

class _ThankYouHeartState extends State<_ThankYouHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 1, end: 1.07)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reduced) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
            dimension: 100,
            child: Center(
                child: ScaleTransition(
                    scale: _scale,
                    child: RepaintBoundary(
                        child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: AppColors.card(context),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.primaryPink
                                  .withValues(alpha: 0.25))),
                      child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Icon(Icons.favorite_rounded,
                              color: AppColors.primaryPink, size: 44)),
                    ))))),
      );
}

class _ProjectLinkCard extends StatelessWidget {
  const _ProjectLinkCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.path,
      this.highlighted = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final String path;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
        link: true,
        child: Material(
          color: AppColors.card(context),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
              side: BorderSide(color: AppColors.border(context))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              await openDevelopmentLink(context, Uri.https('github.com', path));
            },
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(
                          child: Icon(icon,
                              size: 26,
                              color: highlighted
                                  ? AppColors.warning
                                  : colors.primary)),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(title,
                                style: AppTextStyles.cardTitle(context)),
                            const SizedBox(height: 6),
                            Text(subtitle,
                                style: AppTextStyles.bodySecondary(context)),
                          ])),
                      const SizedBox(width: 8),
                      ExcludeSemantics(
                          child: Icon(Icons.open_in_new_rounded,
                              size: 18,
                              color: AppColors.textSecondary(context))),
                    ])),
          ),
        ));
  }
}
