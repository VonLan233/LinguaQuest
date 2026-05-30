import 'package:flutter/material.dart';

import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';

class ClassProgressScreen extends StatelessWidget {
  const ClassProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('校园入门', '92%', 'deadline'),
      ('旅行基础', '64%', 'itinerary'),
      ('职场表达', '38%', 'negotiate'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/class-mode'),
        title: const Text('班级进度'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: '班级概览',
              subtitle: '教师端完成度和弱项词摘要，当前为产品原型界面。',
            ),
            const SizedBox(height: 16),
            for (final row in rows)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(row.$1),
                  subtitle: Text('弱项词：${row.$3}'),
                  trailing: Chip(label: Text(row.$2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
