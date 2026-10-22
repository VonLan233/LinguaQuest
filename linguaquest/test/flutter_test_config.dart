import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keep the regression suite's default UI in English. Tests for Chinese and
/// Japanese select their locale explicitly; the app itself follows preferences.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('en')
    ..localesTestValue = const <Locale>[Locale('en')];
  await testMain();
}
