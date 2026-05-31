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
        title: const Text('Teacher / Class mode'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: 'Class learning',
              subtitle:
                  'Join-code and teacher analytics shell for the next server-backed phase.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Class code',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Joined class ${_codeController.text} (mock)'),
                ),
              ),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Join class'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/class-progress'),
              icon: const Icon(Icons.query_stats_outlined),
              label: const Text('View class progress'),
            ),
          ],
        ),
      ),
    );
  }
}
