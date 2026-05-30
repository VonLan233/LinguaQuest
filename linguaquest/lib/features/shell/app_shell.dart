import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _dragDeltaX = 0,
          onHorizontalDragUpdate: (details) {
            _dragDeltaX += details.primaryDelta ?? 0;
          },
          onHorizontalDragEnd: _handleHorizontalDrag,
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: (index) => _goToIndex(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports_rounded),
            label: '训练场',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_alt_outlined),
            selectedIcon: Icon(Icons.psychology_alt_rounded),
            label: 'AI 学习',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: '发现',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: '我的',
          ),
        ],
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
