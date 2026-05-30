import 'package:flutter/material.dart';

import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final _promptController = TextEditingController(
    text: '解释 affect 和 effect 的区别',
  );

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: const Text('AI 助教'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: '模拟反馈',
              subtitle: '先固定交互模型，后续再接入正式 AI API。',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '询问单词、语法或错题',
                prefixIcon: Icon(Icons.smart_toy_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.psychology_alt_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Affect is usually a verb: "The weather affects my mood." '
                    'Effect is usually a noun: "The effect was immediate." '
                    '你可以分别用两个词各造一个句子。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
