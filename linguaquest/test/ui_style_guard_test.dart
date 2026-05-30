import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UI style guardrails', () {
    test('feature screens avoid heavy card and glass primitives', () {
      final source = _readDartSources(Directory('lib/features'));
      final forbiddenPatterns = [
        (RegExp(r'\bQuestCard\s*\('), 'QuestCard('),
        (RegExp(r'\bCard\s*\('), 'Card('),
        (RegExp(r'\bBoxShadow\b'), 'BoxShadow'),
        (RegExp(r'\bLinearGradient\b'), 'LinearGradient'),
        (RegExp(r'\bRadialGradient\b'), 'RadialGradient'),
        (RegExp(r'\bBackdropFilter\b'), 'BackdropFilter'),
        (RegExp(r'\bImageFilter\b'), 'ImageFilter'),
        (RegExp(r'\bblur\s*\('), 'blur('),
        (RegExp(r'elevation:\s*[1-9]'), 'positive elevation'),
      ];

      for (final (pattern, label) in forbiddenPatterns) {
        expect(
          pattern.hasMatch(source),
          isFalse,
          reason: '$label reintroduces heavy UI treatment.',
        );
      }
    });

    test('legacy quest card abstraction stays removed', () {
      final source = _readDartSources(Directory('lib'));

      expect(File('lib/core/widgets/quest_card.dart').existsSync(), isFalse);
      expect(source, isNot(contains('QuestCard')));
      expect(source, isNot(contains('quest_card.dart')));
    });

    test('brand presence stays icon-led and avoids generic language marks', () {
      final featureSource = _readDartSources(Directory('lib/features'));
      final brandMark = File(
        'lib/core/widgets/brand_mark.dart',
      ).readAsStringSync();
      final brandMarkUses = RegExp(
        r'\bBrandMark\s*\(',
      ).allMatches(featureSource).length;

      expect(brandMark, contains('icon_transparent.png'));
      expect(featureSource, isNot(contains('icon_transparent.png')));
      expect(brandMarkUses, greaterThanOrEqualTo(3));
      expect(brandMarkUses, lessThanOrEqualTo(4));
      expect(featureSource, isNot(contains('Icons.language_outlined')));
      expect(featureSource, isNot(contains('猫')));
      expect(featureSource.toLowerCase(), isNot(contains('whisker')));
      expect(featureSource.toLowerCase(), isNot(contains('paw')));
    });

    test('new study and review stay separate from campus timed tests', () {
      final home = File(
        'lib/features/home/home_screen.dart',
      ).readAsStringSync();
      final training = File(
        'lib/features/training/training_screen.dart',
      ).readAsStringSync();
      final newStudy = File(
        'lib/features/study/new_study_screen.dart',
      ).readAsStringSync();
      final router = File(
        'lib/core/routing/app_router.dart',
      ).readAsStringSync();

      expect(home, contains("context.push('/study/new')"));
      expect(home, contains("context.push('/study/review')"));
      expect(home, isNot(contains('/timed-test/lesson-campus-1')));
      expect(training, contains("context.push('/timed-test/lesson-campus-1')"));
      expect(training, isNot(contains("context.push('/study/review')")));
      expect(training, contains('限时测试'));
      expect(newStudy, contains('不做限时测试'));
      expect(router, contains("path: '/study/new'"));
      expect(router, contains("path: '/study/review'"));
      expect(router, contains("path: '/timed-test/:id'"));
    });

    test('legacy English UI labels do not reappear', () {
      final source = _readDartSources(Directory('lib'));
      const legacyLabels = ['Campus Starter', 'Goal Setup', 'WordBook'];

      for (final label in legacyLabels) {
        expect(source, isNot(contains(label)));
      }
    });
  });
}

String _readDartSources(Directory root) {
  final buffer = StringBuffer();
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    buffer
      ..writeln('// ${file.path}')
      ..writeln(file.readAsStringSync());
  }
  return buffer.toString();
}
