import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

import 'config.dart';

/// Sends transactional emails. The rest of the app depends only on this
/// interface; the concrete sender is chosen by [EmailSender.fromConfig].
abstract class EmailSender {
  Future<void> sendVerificationCode({
    required String to,
    required String code,
  });

  factory EmailSender.fromConfig(AppConfig config) {
    if (config.smtpHost.trim().isEmpty) return ConsoleEmailSender();
    return SmtpEmailSender(config);
  }
}

/// Dev/CI fallback: logs the code to stdout instead of sending an email.
/// Also records the last call so tests can assert on it.
class ConsoleEmailSender implements EmailSender {
  String? lastTo;
  String? lastCode;

  @override
  Future<void> sendVerificationCode({
    required String to,
    required String code,
  }) async {
    lastTo = to;
    lastCode = code;
    stdout.writeln('[email] verification code for $to: $code');
  }
}

/// Real SMTP delivery, used when SMTP_HOST is configured.
class SmtpEmailSender implements EmailSender {
  SmtpEmailSender(this._config);

  final AppConfig _config;

  @override
  Future<void> sendVerificationCode({
    required String to,
    required String code,
  }) async {
    final server = SmtpServer(
      _config.smtpHost,
      port: _config.smtpPort,
      username: _config.smtpUsername.isEmpty ? null : _config.smtpUsername,
      password: _config.smtpPassword.isEmpty ? null : _config.smtpPassword,
    );
    final message = Message()
      ..from = Address(_config.smtpFrom, 'LinguaQuest')
      ..recipients.add(to)
      ..subject = 'Your LinguaQuest verification code'
      ..text = 'Your verification code is $code. It expires in 10 minutes.';
    await send(message, server);
  }
}
