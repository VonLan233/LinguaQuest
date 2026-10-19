import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import 'app_drawer.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.selectedIndex, required this.child, super.key});

  final int selectedIndex;
  final Widget child;

  static const routes = [
    '/home',
    '/training',
    '/ai-learning',
    '/discover',
    '/profile',
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _minimumSwipeDistance = 72.0;
  static const _minimumFlingDistance = 36.0;
  static const _minimumFlingVelocity = 650.0;
  static const _pageSwipeFraction = 0.20;

  Offset _pageOffset = Offset.zero;
  double _dragDeltaX = 0;

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _pageOffset = Offset(
        widget.selectedIndex > oldWidget.selectedIndex ? 1 : -1,
        0,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _pageOffset = Offset.zero);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        drawer: const AppDrawer(),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => _dragDeltaX = 0,
            onHorizontalDragUpdate: (details) {
              _dragDeltaX += details.primaryDelta ?? 0;
            },
            onHorizontalDragEnd: _handleHorizontalDrag,
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ClipRect(
                child: AnimatedSlide(
                  offset: _pageOffset,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _QuestBottomNav(
          selectedIndex: widget.selectedIndex,
          onSelected: (index) => _goToIndex(context, index),
        ),
      ),
    );
  }

  void _handleHorizontalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final width = MediaQuery.sizeOf(context).width;
    final distanceThreshold = (width * _pageSwipeFraction).clamp(
      _minimumSwipeDistance,
      180.0,
    );
    final distance = _dragDeltaX.abs();
    final isDeliberateDrag = distance >= distanceThreshold;
    final isMeaningfulFling =
        distance >= _minimumFlingDistance &&
        velocity.abs() >= _minimumFlingVelocity;
    if (!isDeliberateDrag && !isMeaningfulFling) return;

    final direction = isDeliberateDrag ? _dragDeltaX : velocity;
    final nextIndex = direction < 0
        ? widget.selectedIndex + 1
        : widget.selectedIndex - 1;
    if (nextIndex < 0 || nextIndex >= AppShell.routes.length) return;
    _goToIndex(context, nextIndex);
  }

  void _goToIndex(BuildContext context, int index) {
    if (index == widget.selectedIndex) return;
    context.go(AppShell.routes[index]);
  }
}

class _QuestBottomNav extends StatelessWidget {
  const _QuestBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static List<_QuestTabData> _buildTabs(AppLocalizations l10n) {
    return [
      _QuestTabData(
        label: l10n.tabHome,
        icon: AppIcons.home,
        color: AppTheme.teal,
      ),
      _QuestTabData(
        label: l10n.tabTraining,
        icon: Icons.school_outlined,
        color: AppTheme.leaf,
      ),
      _QuestTabData(
        label: l10n.tabAiLearning,
        icon: Icons.chat_bubble_outline_rounded,
        color: AppTheme.cyan,
      ),
      _QuestTabData(
        label: l10n.tabDiscover,
        icon: AppIcons.explore,
        color: AppTheme.mango,
      ),
      _QuestTabData(
        label: l10n.tabProfile,
        icon: AppIcons.person,
        color: AppTheme.teal,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tabs = _buildTabs(l10n);
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s8),
              child: Row(
                children: [
                  for (var index = 0; index < tabs.length; index++)
                    Expanded(
                      child: _QuestTabButton(
                        data: tabs[index],
                        selected: selectedIndex == index,
                        onTap: () => onSelected(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestTabButton extends StatelessWidget {
  const _QuestTabButton({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _QuestTabData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tabColor = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      label: data.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.s4,
              vertical: AppTokens.s8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _QuestTabIcon(data: data, selected: selected, color: tabColor),
                const SizedBox(height: AppTokens.s4),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tabColor,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestTabIcon extends StatelessWidget {
  const _QuestTabIcon({
    required this.data,
    required this.selected,
    required this.color,
  });

  final _QuestTabData data;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: AppTokens.fast,
      curve: Curves.easeOutCubic,
      width: 44,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Icon(data.icon, color: color, size: 22, fill: selected ? 1 : 0),
    );
  }
}

class _QuestTabData {
  const _QuestTabData({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
