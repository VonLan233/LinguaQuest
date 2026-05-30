import 'package:flutter/material.dart';

import '../../core/widgets/fallback_back_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: const Text('关于我们'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'LinguaQuest',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('词境星球 · 版本 1.0.0'),
            const SizedBox(height: 20),
            const Text(
              'LinguaQuest 将图像词卡、学习路径、间隔复习、XP、连续打卡和个人生词卡整合到一个移动优先的英语学习应用中。',
            ),
            const SizedBox(height: 20),
            const ListTile(
              leading: Icon(Icons.flag_outlined),
              title: Text('项目目标'),
              subtitle: Text('通过短课节、错题修复和可见进度，帮助学习者建立每日英语学习习惯。'),
            ),
            const ListTile(
              leading: Icon(Icons.groups_outlined),
              title: Text('开发团队'),
              subtitle: Text('ASM2 Mobile 团队。专注移动优先的英语学习体验。'),
            ),
            const ListTile(
              leading: Icon(Icons.extension_outlined),
              title: Text('核心体验'),
              subtitle: Text('目标规划、视觉词汇、测验练习、复习排程和个人词卡。'),
            ),
            const ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('隐私'),
              subtitle: Text('自定义词卡和学习记录仅归属于当前登录用户。'),
            ),
          ],
        ),
      ),
    );
  }
}
