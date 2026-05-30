import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
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
            for (final row in rows) _ClassProgressRow(row: row),
          ],
        ),
      ),
    );
  }
}

class _ClassProgressRow extends StatelessWidget {
  const _ClassProgressRow({required this.row});

  final (String, String, String) row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.assignment_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.$1, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '弱项词：${row.$3}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PillLabel(label: row.$2, color: AppTheme.cyan),
        ],
      ),
    );
  }
}
