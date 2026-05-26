import 'package:flutter/material.dart';

import '../../core/widgets/fallback_back_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminders = true;
  bool _sound = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              value: _reminders,
              onChanged: (value) => setState(() => _reminders = value),
              title: const Text('Daily reminder'),
              subtitle: const Text('20:00 local reminder placeholder'),
            ),
            SwitchListTile(
              value: _sound,
              onChanged: (value) => setState(() => _sound = value),
              title: const Text('Quiz sound feedback'),
              subtitle: const Text(
                'Prepared for future audio pronunciation support',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.dark_mode_outlined),
              title: Text('Theme'),
              subtitle: Text('Uses the system light/dark preference'),
            ),
          ],
        ),
      ),
    );
  }
}
