import 'dart:async';

/// 等待 TTS 播放完成：注册完成/错误回调后调用 [speak]；完成→true，错误→false，
/// 超时→false（兜底，避免 flutter_tts 在部分平台 speak() 的 Future 永不 resolve）。
///
/// ponytail: 不追求精确取消语义——_tts.stop() 被调用时旧 Completer 可能悬空，
/// 由 [timeout] 兜底保证最终返回。升级路径：若需精确取消，可改用 CancelableOperation。
Future<bool> awaitTtsCompletion({
  required void Function(void Function()) registerCompletion,
  required void Function(void Function()) registerError,
  required Future<void> Function() speak,
  Duration timeout = const Duration(seconds: 8),
}) async {
  final completer = Completer<bool>();
  registerCompletion(() {
    if (!completer.isCompleted) completer.complete(true);
  });
  registerError(() {
    if (!completer.isCompleted) completer.complete(false);
  });
  await speak();
  return completer.future.timeout(timeout, onTimeout: () => false);
}
