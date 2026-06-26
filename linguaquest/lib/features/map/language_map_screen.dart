import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/target_language_picker.dart';
import '../../l10n/generated/app_localizations.dart';

/// Coordinate and metadata for each language pin on the world map.
class _LangPin {
  const _LangPin({
    required this.code,
    required this.label,
    required this.point,
    required this.enabled,
  });

  final String code;
  final String label;
  final LatLng point;
  final bool enabled;
}

const _langPins = [
  _LangPin(
    code: 'zh',
    label: 'Chinese (中文)',
    point: LatLng(39.9087, 116.3975), // Beijing, China
    enabled: true,
  ),
  _LangPin(
    code: 'en',
    label: 'English',
    point: LatLng(38.0, -97.0), // United States
    enabled: false,
  ),
  _LangPin(
    code: 'es',
    label: 'Spanish (Español)',
    point: LatLng(40.4, -3.7), // Spain
    enabled: false,
  ),
  _LangPin(
    code: 'fr',
    label: 'French (Français)',
    point: LatLng(46.6, 2.3), // France
    enabled: false,
  ),
  _LangPin(
    code: 'ja',
    label: 'Japanese (日本語)',
    point: LatLng(36.2, 138.2), // Japan
    enabled: false,
  ),
  _LangPin(
    code: 'ms',
    label: 'Malay (Bahasa Melayu)',
    point: LatLng(4.2, 101.9), // Malaysia
    enabled: false,
  ),
];

/// A full-screen world map where country markers represent learnable languages.
/// Tapping the China marker (zh, enabled) drives a real language-selection flow;
/// coming-soon markers show a localized snackbar.
class LanguageMapScreen extends ConsumerWidget {
  const LanguageMapScreen({super.key});

  void _onPinTap(
    BuildContext context,
    WidgetRef ref,
    _LangPin pin,
  ) {
    final l10n = AppLocalizations.of(context);

    if (pin.enabled) {
      // Enabled pin (zh): show bottom sheet with confirm action
      final label = targetLanguageLabel(pin.code);
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.s16),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.languageMapSelectPrompt,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: AppTokens.s16),
                  AppPrimaryButton(
                    key: ValueKey('lang-confirm-${pin.code}'),
                    label: l10n.languageMapConfirm(label),
                    onPressed: () async {
                      await ref
                          .read(appControllerProvider.notifier)
                          .updateTargetLanguage(pin.code);
                      if (sheetCtx.mounted) {
                        Navigator.of(sheetCtx).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.languageMapSelected(label)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Coming-soon pin: show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.languageMapComingSoon(pin.label)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    const muted = Colors.grey;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.languageMapTitle),
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(20, 80),
          initialZoom: 2.2,
          minZoom: 1,
          maxZoom: 6,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.linguaquest',
          ),
          MarkerLayer(
            markers: [
              for (final pin in _langPins)
                Marker(
                  point: pin.point,
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    key: ValueKey('lang-pin-${pin.code}'),
                    onTap: () => _onPinTap(context, ref, pin),
                    child: Icon(
                      Icons.place,
                      color: pin.enabled ? primary : muted,
                      size: 36,
                    ),
                  ),
                ),
            ],
          ),
          RichAttributionWidget(
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}
