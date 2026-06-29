import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icons.dart';

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
        top: false,
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
            item(AppIcons.language, 'Choose Language', '/language-map'),
            item(AppIcons.search, 'Search', '/search'),
            item(AppIcons.person, 'Profile', '/profile'),
            item(AppIcons.settings, 'Settings', '/settings'),
            item(AppIcons.help, 'Help', '/help'),
            item(AppIcons.info, 'About', '/about'),
          ],
        ),
      ),
    );
  }
}
