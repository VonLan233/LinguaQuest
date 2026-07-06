import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final infos = <(IconData, Color, String, String)>[
      (
        AppIcons.flag,
        AppTokens.azure,
        l10n.aboutGoalTitle,
        l10n.aboutGoalSubtitle,
      ),
      (
        AppIcons.groups,
        AppTokens.successColor(context),
        l10n.aboutTeamTitle,
        l10n.aboutTeamSubtitle,
      ),
      (
        AppIcons.extension,
        AppTokens.mangoColor(context),
        l10n.aboutCoreTitle,
        l10n.aboutCoreSubtitle,
      ),
      (
        AppIcons.privacyTip,
        AppTokens.coralColor(context),
        l10n.aboutPrivacyTitle,
        l10n.aboutPrivacySubtitle,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: Text(l10n.profileAboutTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            AppCard(
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.s20),
                decoration: BoxDecoration(
                  color: AppTokens.brandNavy,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LinguaQuest',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (c, snap) => Text(
                        l10n.aboutVersion(snap.data?.version ?? ''),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            AppCard(
              padding: const EdgeInsets.all(AppTokens.s20),
              child: Text(l10n.aboutIntro, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: AppTokens.s16),
            AppCard(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                children: [
                  for (var i = 0; i < infos.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppTokens.s16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(infos[i].$1, color: infos[i].$2),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                infos[i].$3,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppTokens.s4),
                              Text(
                                infos[i].$4,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            // Company locator map card
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aboutCompanyName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          l10n.aboutCompanyAddress,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppTokens.s4),
                        Text(
                          l10n.aboutCompanyDescription,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppTokens.radiusCard),
                      bottomRight: Radius.circular(AppTokens.radiusCard),
                    ),
                    child: SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: const MapOptions(
                          initialCenter: LatLng(2.8316, 101.7070),
                          initialZoom: 14,
                          interactionOptions: InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.linguaquest',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: const LatLng(2.8316, 101.7070),
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.place,
                                  key: const ValueKey('company-pin'),
                                  color: AppTokens.coral,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                          RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution(
                                '© OpenStreetMap contributors',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
