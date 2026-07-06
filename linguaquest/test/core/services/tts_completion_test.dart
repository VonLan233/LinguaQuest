import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/services/tts_completion.dart';

void main() {
  test('完成回调触发 → true', () async {
    void Function()? onDone;
    final result = await awaitTtsCompletion(
      registerCompletion: (cb) => onDone = cb,
      registerError: (_) {},
      speak: () async => onDone!(),
      timeout: const Duration(seconds: 1),
    );
    expect(result, isTrue);
  });

  test('从不完成 → 超时返回 false', () async {
    final result = await awaitTtsCompletion(
      registerCompletion: (_) {},
      registerError: (_) {},
      speak: () async {},
      timeout: const Duration(milliseconds: 50),
    );
    expect(result, isFalse);
  });

  test('错误回调触发 → false', () async {
    void Function()? onErr;
    final result = await awaitTtsCompletion(
      registerCompletion: (_) {},
      registerError: (cb) => onErr = cb,
      speak: () async => onErr!(),
      timeout: const Duration(seconds: 1),
    );
    expect(result, isFalse);
  });

  test('speak Future 永不 resolve → 超时返回 false', () async {
    final neverCompletes = Completer<void>();
    final result = await awaitTtsCompletion(
      registerCompletion: (_) {},
      registerError: (_) {},
      speak: () => neverCompletes.future,
      timeout: const Duration(milliseconds: 50),
    );
    expect(result, isFalse);
  });
}
