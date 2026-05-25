import 'package:flutter/material.dart';

import '../../core/widgets/section_header.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final _promptController = TextEditingController(
    text: 'Explain affect vs effect',
  );

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI tutor')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: 'Mock feedback',
              subtitle:
                  'This screen locks the interaction model before any paid AI API is connected.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Ask about a word or mistake',
                prefixIcon: Icon(Icons.smart_toy_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Affect is usually a verb: "The weather affects my mood." '
                  'Effect is usually a noun: "The effect was immediate." '
                  'Try making one sentence with each word.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
