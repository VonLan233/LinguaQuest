import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.selectedIndex, required this.child, super.key});

  final int selectedIndex;
  final Widget child;

  static const _routes = ['/home', '/learn', '/review', '/quest', '/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => context.go(_routes[index]),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.route_outlined),
                selectedIcon: Icon(Icons.route_rounded),
                label: 'Learn',
              ),
              NavigationDestination(
                icon: Icon(Icons.replay_outlined),
                selectedIcon: Icon(Icons.replay_rounded),
                label: 'Review',
              ),
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events_rounded),
                label: 'Quest',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
