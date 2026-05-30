import 'package:flutter/material.dart';

import '../../core/widgets/fallback_back_button.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faqs = [
      ('复习时间如何安排？', '每个词会在 0-5 的掌握度之间变化，掌握度越高，下次复习间隔越长。'),
      ('可以添加自己的单词吗？', '可以。进入单词本或生词本，点击添加即可创建个人词卡。'),
      ('AI 助教可以做什么？', '可以解释单词、语法和错题，并给出适合继续练习的例句。'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: const Text('帮助与反馈'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final faq in faqs)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(faq.$1),
                childrenPadding: const EdgeInsets.only(bottom: 16),
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text(faq.$2)),
                ],
              ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.mail_outline),
              title: Text('联系支持'),
              subtitle: Text('support@lingua.quest'),
            ),
          ],
        ),
      ),
    );
  }
}
