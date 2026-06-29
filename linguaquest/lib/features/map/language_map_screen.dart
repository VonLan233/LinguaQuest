import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/language_wordbook_picker.dart';
import '../../l10n/generated/app_localizations.dart';

/// 每个语言图钉的坐标与元数据。
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
  _LangPin(code: 'zh', label: 'Chinese (中文)', point: LatLng(39.9087, 116.3975), enabled: true),
  _LangPin(code: 'en', label: 'English', point: LatLng(38.0, -97.0), enabled: false),
  _LangPin(code: 'es', label: 'Spanish (Español)', point: LatLng(40.4, -3.7), enabled: false),
  _LangPin(code: 'fr', label: 'French (Français)', point: LatLng(46.6, 2.3), enabled: false),
  _LangPin(code: 'ja', label: 'Japanese (日本語)', point: LatLng(36.2, 138.2), enabled: true),
  _LangPin(code: 'ms', label: 'Malay (Bahasa Melayu)', point: LatLng(4.2, 101.9), enabled: false),
];

/// 全屏世界地图（真 OSM 瓦片）：国家 marker 代表可学语言。点击 marker 弹卡片，
/// 可学语言进入两级词书选择，未开放显示"即将开放"。
class LanguageMapScreen extends ConsumerStatefulWidget {
  const LanguageMapScreen({super.key});

  @override
  ConsumerState<LanguageMapScreen> createState() => _LanguageMapScreenState();
}

class _LanguageMapScreenState extends ConsumerState<LanguageMapScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  _LangPin? get _selected =>
      _selectedCode == null ? null : _langPins.firstWhere((p) => p.code == _selectedCode);

  Future<void> _startLearning(_LangPin pin) async {
    await ref.read(appControllerProvider.notifier).updateTargetLanguage(pin.code);
    if (!mounted) return;
    await showLanguageWordbookPicker(context, initialLanguage: pin.code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final sel = _selected;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.languageMapTitle),
      ),
      body: Stack(
        children: [
          FlutterMap(
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
              if (isDark)
                IgnorePointer(
                  child: Container(
                    color: const Color(0xFF0E1626).withValues(alpha: 0.55),
                  ),
                ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _langPins.length; i++)
                    Marker(
                      point: _langPins[i].point,
                      width: 140,
                      height: 110,
                      alignment: Alignment.topCenter,
                      child: _LangMarker(
                        pin: _langPins[i],
                        index: i,
                        entrance: _entrance,
                        pulse: _pulse,
                        selected: _selectedCode == _langPins[i].code,
                        onTap: () =>
                            setState(() => _selectedCode = _langPins[i].code),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          // 顶部引导条
          Positioned(
            top: AppTokens.s12,
            left: AppTokens.s16,
            right: AppTokens.s16,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16, vertical: AppTokens.s12),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Text(
                  l10n.languageMapSelectPrompt,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
          // 底部图例
          Positioned(
            left: AppTokens.s16,
            bottom: AppTokens.s16,
            child: IgnorePointer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(color: cs.primary, label: 'Available'),
                  const SizedBox(width: AppTokens.s12),
                  _LegendDot(color: cs.onSurfaceVariant, label: 'Coming soon'),
                ],
              ),
            ),
          ),
          // 选中卡片
          if (sel != null)
            Positioned(
              left: AppTokens.s16,
              right: AppTokens.s16,
              bottom: AppTokens.s16,
              child: _LangCard(
                key: const ValueKey('lang-card'),
                pin: sel,
                l10n: l10n,
                onClose: () => setState(() => _selectedCode = null),
                onStart: () => _startLearning(sel),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTokens.s8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ]),
    );
  }
}

class _LangMarker extends StatelessWidget {
  const _LangMarker({
    required this.pin,
    required this.index,
    required this.entrance,
    required this.pulse,
    required this.selected,
    required this.onTap,
  });
  final _LangPin pin;
  final int index;
  final Animation<double> entrance;
  final Animation<double> pulse;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = (index * 0.12).clamp(0.0, 0.6);
    final curve = Interval(start, (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutBack);
    return GestureDetector(
      key: ValueKey('lang-pin-${pin.code}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([entrance, pulse]),
        builder: (context, _) {
          final t = curve.transform(entrance.value).clamp(0.0, 1.0);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * -10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(color: cs.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      pin.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: pin.enabled ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Badge(pin: pin, selected: selected, pulse: pulse.value),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.pin, required this.selected, required this.pulse});
  final _LangPin pin;
  final bool selected;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final glow = pin.enabled || selected;
    final ring = (selected ? 44.0 : 36.0) *
        (1.0 + (pin.enabled ? pulse * 0.22 : 0.0));
    final dot = selected ? 30.0 : 26.0;
    final glowColor = pin.enabled ? cs.primary : cs.onSurfaceVariant;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            Container(
              width: ring,
              height: ring,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withValues(alpha: selected ? 0.30 : 0.16),
              ),
            ),
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: pin.enabled
                  ? LinearGradient(
                      colors: [cs.primary, AppTokens.sky],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: pin.enabled ? null : cs.surfaceContainerHighest,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: pin.enabled
                ? null
                : Icon(Icons.lock, size: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({
    super.key,
    required this.pin,
    required this.l10n,
    required this.onClose,
    required this.onStart,
  });
  final _LangPin pin;
  final AppLocalizations l10n;
  final VoidCallback onClose;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pin.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s8),
            if (pin.enabled)
              SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  key: const ValueKey('lang-card-start'),
                  label: l10n.languageMapConfirm(pin.label),
                  onPressed: onStart,
                ),
              )
            else
              AppPill(
                key: const ValueKey('lang-card-soon'),
                label: l10n.languageMapComingSoon(pin.label),
                variant: PillVariant.neutral,
              ),
          ],
        ),
      ),
    );
  }
}
