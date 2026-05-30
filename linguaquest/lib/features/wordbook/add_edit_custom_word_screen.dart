import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../data/models/custom_word.dart';

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
  final _tagController = TextEditingController(text: 'custom');
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
    final existing = _existingWord();
    if (!_hydrated && existing != null) {
      _hydrate(existing);
    }
    final isEditing = existing != null;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/custom-words'),
        title: Text(isEditing ? '编辑单词' : '添加单词'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _wordController,
                  decoration: const InputDecoration(
                    labelText: '单词',
                    prefixIcon: Icon(Icons.abc),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _meaningController,
                  decoration: const InputDecoration(
                    labelText: '释义',
                    prefixIcon: Icon(Icons.translate),
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _exampleController,
                  decoration: const InputDecoration(
                    labelText: '例句',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  minLines: 2,
                  maxLines: 4,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: '笔记',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    labelText: '标签',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Easy', label: Text('简单')),
                    ButtonSegment(value: 'Medium', label: Text('中等')),
                    ButtonSegment(value: 'Hard', label: Text('困难')),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (values) =>
                      setState(() => _difficulty = values.first),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => _save(existing),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(isEditing ? '保存修改' : '创建单词'),
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
    _tagController.text = word.tag;
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
              ? 'custom'
              : _tagController.text.trim(),
          difficulty: _difficulty,
        ),
      );
    }
    if (!mounted) return;
    if (!succeeded) {
      final message = ref.read(appControllerProvider).errorMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message ?? '暂时无法保存这个单词')));
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('单词已保存')));
    context.go('/custom-words');
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) return '必填';
  return null;
}
