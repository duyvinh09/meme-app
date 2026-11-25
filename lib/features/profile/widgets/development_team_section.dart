import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/extensions/localization_extension.dart';

class DevelopmentTeamSection extends StatelessWidget {
  const DevelopmentTeamSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ExcludeSemantics(
            child: Icon(Icons.groups_outlined,
                color: Theme.of(context).colorScheme.primary, size: 28)),
        const SizedBox(width: 12),
        Expanded(
            child: Semantics(
                header: true,
                child: Text(l10n.developmentTeam,
                    style: AppTextStyles.sectionTitle(context)))),
      ]),
      const SizedBox(height: 8),
      Text(l10n.developmentTeamIntro,
          style: AppTextStyles.bodySecondary(context)),
      const SizedBox(height: 20),
      _DeveloperCard(
          name: 'Đinh Duy Vinh',
          initials: 'DV',
          username: 'duyvinh09',
          role: l10n.developerLeadRole),
      const SizedBox(height: 12),
      _DeveloperCard(
          name: 'Lê Anh Nam',
          initials: 'AN',
          username: 'NamLe1808',
          role: l10n.developerLanguageAiRole),
      const SizedBox(height: 12),
      _DeveloperCard(
          name: 'Phạm Ngọc Vũ',
          initials: 'NV',
          username: 'Ngocvu2604',
          role: l10n.developerDesignAiTestingRole),
      const SizedBox(height: 12),
      _DeveloperCard(
          name: 'Trần Nguyễn Quốc Huy',
          initials: 'QH',
          username: 'QHuy1202',
          role: l10n.developerBillLogicRole),
    ]);
  }
}

class _DeveloperCard extends StatelessWidget {
  const _DeveloperCard(
      {required this.name,
      required this.initials,
      required this.username,
      required this.role});
  final String name;
  final String initials;
  final String username;
  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      link: true,
      child: Material(
        color: AppColors.surface(context),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
            side: BorderSide(color: AppColors.border(context))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await openDevelopmentLink(
                context, Uri.https('github.com', '/$username'));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ExcludeSemantics(
                  child: CircleAvatar(
                      radius: 21,
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      child: ClipOval(
                          child: CachedNetworkImage(
                        imageUrl: 'https://github.com/$username.png?size=128',
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        memCacheWidth: 128,
                        fadeInDuration: Duration.zero,
                        placeholder: (context, url) =>
                            Center(child: Text(initials)),
                        errorWidget: (context, url, error) =>
                            Center(child: Text(initials)),
                      )))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name, style: AppTextStyles.cardTitle(context)),
                    const SizedBox(height: 6),
                    Text(role, style: AppTextStyles.bodySecondary(context)),
                    const SizedBox(height: 10),
                    Row(children: [
                      ExcludeSemantics(
                          child: Icon(Icons.open_in_new_rounded,
                              size: 14,
                              color: AppColors.textSecondary(context))),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text('github.com/$username',
                              style: AppTextStyles.caption(context))),
                    ]),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }
}

Future<void> openDevelopmentLink(BuildContext context, Uri uri) async {
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception {
    opened = false;
  }
  if (!context.mounted || opened) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.l10n.developerLinkError)));
}
