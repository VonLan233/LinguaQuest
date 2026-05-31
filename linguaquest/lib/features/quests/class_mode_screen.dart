import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';

class ClassModeScreen extends StatefulWidget {
  const ClassModeScreen({super.key});

  @override
  State<ClassModeScreen> createState() => _ClassModeScreenState();
}

class _ClassModeScreenState extends State<ClassModeScreen> {
  final _codeController = TextEditingController(text: 'LQ-2048');

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: const Text('班级模式'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: '班级学习',
              subtitle: '输入班级码加入小组，查看班级进度和弱项摘要。',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: '班级码',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已加入班级 ${_codeController.text}')),
              ),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('加入班级'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/class-progress'),
              icon: const Icon(Icons.query_stats_outlined),
              label: const Text('查看班级进度'),
            ),
          ],
        ),
      ),
    );
  }
}
