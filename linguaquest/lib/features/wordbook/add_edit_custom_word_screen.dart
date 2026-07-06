import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:linguaquest/core/theme/app_icons.dart';
import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/custom_word.dart';
import '../../l10n/generated/app_localizations.dart';

class AddEditCustomWordScreen extends ConsumerStatefulWidget {
  const AddEditCustomWordScreen({this.wordId, super.key});

  final String? wordId;

  @override
  ConsumerState<AddEditCustomWordScreen> createState() =>
      _AddEditCustomWordScreenState();
}

class _AddEditCustomWordScreenState
    extends ConsumerState<AddEditCustomWordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagController = TextEditingController(text: '自定义');
  String _difficulty = 'Medium';
  bool _hydrated = false;

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existing = _existingWord();
    if (!_hydrated && existing != null) {
      _hydrate(existing);
    }
    final isEditing = existing != null;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/custom-words'),
        title: Text(
          isEditing ? l10n.customWordsEditTitle : l10n.customWordsAddTitle,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTokens.s20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _wordController,
                        decoration: InputDecoration(
                          labelText: l10n.customWordsFieldWord,
                          prefixIcon: const Icon(AppIcons.abc),
                        ),
                        validator: (value) => _required(value, l10n),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      TextFormField(
                        controller: _meaningController,
                        decoration: InputDecoration(
                          labelText: l10n.customWordsFieldMeaning,
                          prefixIcon: const Icon(AppIcons.translate),
                        ),
                        validator: (value) => _required(value, l10n),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      TextFormField(
                        controller: _exampleController,
                        decoration: InputDecoration(
                          labelText: l10n.customWordsFieldExample,
                          prefixIcon: const Icon(AppIcons.notes),
                        ),
                        minLines: 2,
                        maxLines: 4,
                        validator: (value) => _required(value, l10n),
                      ),
                      const SizedBox(height: AppTokens.s12),
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: l10n.customWordsFieldNote,
                          prefixIcon: const Icon(AppIcons.editNote),
                        ),
                        minLines: 2,
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppTokens.s12),
                      TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          labelText: l10n.customWordsFieldTag,
                          prefixIcon: const Icon(AppIcons.sell),
                        ),
                      ),
                      const SizedBox(height: AppTokens.s16),
                      _DifficultySelector(
                        selected: _difficulty,
                        onSelected: (value) =>
                            setState(() => _difficulty = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s24),
                AppPrimaryButton(
                  icon: AppIcons.save,
                  label: isEditing
                      ? l10n.customWordsSaveEdit
                      : l10n.customWordsCreate,
                  onPressed: () => _save(existing),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  CustomWord? _existingWord() {
    final id = widget.wordId;
    if (id == null) return null;
    for (final word in ref.watch(appControllerProvider).customWords) {
      if (word.id == id) return word;
    }
    return null;
  }

  void _hydrate(CustomWord word) {
    _wordController.text = word.word;
    _meaningController.text = word.meaning;
    _exampleController.text = word.exampleSentence;
    _noteController.text = word.note;
    _tagController.text = displayCustomTag(word.tag);
    _difficulty = word.difficulty;
    _hydrated = true;
  }

  Future<void> _save(CustomWord? existing) async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(appControllerProvider.notifier);
    late final bool succeeded;
    if (existing == null) {
      succeeded = await controller.addCustomWord(
        word: _wordController.text,
        meaning: _meaningController.text,
        exampleSentence: _exampleController.text,
        note: _noteController.text,
        tag: _tagController.text,
        difficulty: _difficulty,
      );
    } else {
      succeeded = await controller.updateCustomWord(
        existing.copyWith(
          word: _wordController.text.trim(),
          meaning: _meaningController.text.trim(),
          exampleSentence: _exampleController.text.trim(),
          note: _noteController.text.trim(),
          tag: _tagController.text.trim().isEmpty
              ? '自定义'
              : _tagController.text.trim(),
          difficulty: _difficulty,
        ),
      );
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    if (!succeeded) {
      final message = ref.read(appControllerProvider).errorMessage;
      // Add path with no error = the word already exists (idempotent no-op):
      // tell the user it's already there instead of the generic "saved"/"failed".
      final text =
          message ??
          (existing == null
              ? l10n.customWordsAlreadyInWordbook
              : l10n.customWordsSaveFailed);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(text)));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.customWordsSaved)));
    context.go('/custom-words');
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choices = const [
      (value: 'Easy', color: AppTheme.teal),
      (value: 'Medium', color: AppTheme.mango),
      (value: 'Hard', color: AppTheme.coral),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customWordsDifficulty,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var index = 0; index < choices.length; index++) ...[
              Expanded(
                child: FilterPillButton(
                  label: displayDifficulty(choices[index].value, l10n: l10n),
                  selected: selected == choices[index].value,
                  onSelected: () => onSelected(choices[index].value),
                  color: choices[index].color,
                ),
              ),
              if (index != choices.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

String? _required(String? value, AppLocalizations l10n) {
  if (value == null || value.trim().isEmpty) return l10n.commonRequired;
  return null;
}
