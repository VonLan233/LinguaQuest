import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: Text(l10n.questClassMode),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(
              title: l10n.classModeTitle,
              subtitle: l10n.classModeSubtitle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: l10n.questClassCode,
                prefixIcon: const Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.classModeJoined(_codeController.text)),
                ),
              ),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.classModeJoin),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/class-progress'),
              icon: const Icon(Icons.query_stats_outlined),
              label: Text(l10n.classModeViewProgress),
            ),
          ],
        ),
      ),
    );
  }
}
