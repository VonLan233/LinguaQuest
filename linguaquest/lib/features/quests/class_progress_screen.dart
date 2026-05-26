import 'package:flutter/material.dart';

import '../../core/widgets/section_header.dart';

class ClassProgressScreen extends StatelessWidget {
  const ClassProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Campus Starter', '92%', 'deadline'),
      ('Travel Basics', '64%', 'itinerary'),
      ('Workplace Moves', '38%', 'negotiate'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Class progress')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: 'Class overview',
              subtitle:
                  'Teacher-facing completion and weak-word summary shell.',
            ),
            const SizedBox(height: 16),
            for (final row in rows)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(row.$1),
                  subtitle: Text('Weak word: ${row.$3}'),
                  trailing: Chip(label: Text(row.$2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
