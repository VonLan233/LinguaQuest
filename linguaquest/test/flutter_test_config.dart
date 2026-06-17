import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global test setup. The app now follows the system language (see
/// `resolveAppLocale` in `lib/app.dart`) instead of hard-coding Chinese, so the
/// test harness must declare a locale — otherwise widgets render in the default
/// test locale (en) and the suite's Chinese-text finders miss. Pin it to `zh`
/// to preserve the existing tests' Chinese-UI expectations.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher
    ..localeTestValue = const Locale('zh')
    ..localesTestValue = const <Locale>[Locale('zh')];
  await testMain();
}
