import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, String route) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: () {
            Navigator.of(context).pop();
            context.go(route);
          },
        );
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('LinguaQuest',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
            ),
            item(Icons.map, 'Study Map', '/map'),
            item(Icons.place, 'Study Spots', '/map/spots'),
            item(Icons.search, 'Search', '/search'),
            item(Icons.person, 'Profile', '/profile'),
            item(Icons.settings, 'Settings', '/settings'),
            item(Icons.help_outline, 'Help', '/help'),
            item(Icons.info_outline, 'About', '/about'),
          ],
        ),
      ),
    );
  }
}
