import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/class_group.dart';

class ClassModeScreen extends ConsumerStatefulWidget {
  const ClassModeScreen({super.key});

  @override
  ConsumerState<ClassModeScreen> createState() => _ClassModeScreenState();
}

class _ClassModeScreenState extends ConsumerState<ClassModeScreen> {
  final _codeController = TextEditingController(text: 'LQ-2048');
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: const Text('班级模式'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(classesProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(
                title: '班级学习',
                subtitle: '输入班级码加入小组，服务器会同步成员进度和弱项摘要。',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: '班级码',
                  prefixIcon: Icon(Icons.key_outlined),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isJoining ? null : _joinClass,
                icon: _isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.group_add_outlined),
                label: Text(_isJoining ? '加入中' : '加入班级'),
              ),
              const SizedBox(height: 22),
              const SectionHeader(title: '我的班级', subtitle: '查看已加入班级的学习进度。'),
              const SizedBox(height: 12),
              classes.when(
                data: (items) => _ClassList(classes: items),
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => Text(
                  '暂时无法同步班级列表，请稍后重试。',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _joinClass() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() => _isJoining = true);
    try {
      final joined = await ref
          .read(appServicesRepositoryProvider)
          .joinClass(code);
      ref.invalidate(classesProvider);
      ref.invalidate(classProgressProvider(''));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已加入 ${joined.name}')));
      context.push('/class-progress?classId=${joined.id}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('暂时无法加入班级：$error'),
          backgroundColor: AppTheme.coral,
        ),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }
}

class _ClassList extends StatelessWidget {
  const _ClassList({required this.classes});

  final List<ClassGroup> classes;

  @override
  Widget build(BuildContext context) {
    if (classes.isEmpty) {
      return Text(
        '还没有加入班级。输入班级码后即可查看班级进度。',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < classes.length; index++) ...[
          _ClassRow(classGroup: classes[index]),
          if (index != classes.length - 1)
            Divider(
              height: 14,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
        ],
      ],
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.classGroup});

  final ClassGroup classGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/class-progress?classId=${classGroup.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconCueBadge(icon: Icons.groups_outlined, color: AppTheme.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classGroup.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${classGroup.code} · ${classGroup.memberCount} 名成员',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const PillLabel(label: '进度', color: AppTheme.cyan),
            ],
          ),
        ),
      ),
    );
  }
}
