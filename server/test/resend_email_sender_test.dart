import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/email_sender.dart';
import 'package:test/test.dart';

const _base = AppConfig(port: 0, databaseUrl: 'x', jwtSecret: 'y');

void main() {
  test('posts a correct request to the Resend API', () async {
    http.Request? captured;
    final client = MockClient((req) async {
      captured = req;
      return http.Response('{"id":"email_123"}', 200);
    });
    final config = _base.copyWith(
      resendApiKey: 're_test_key',
      mailFrom: 'no-reply@vonlan233.top',
    );
    final sender = ResendEmailSender(config, client: client);

    await sender.sendVerificationCode(to: 'user@example.com', code: '123456');

    expect(captured, isNotNull);
    expect(captured!.method, 'POST');
    expect(captured!.url.toString(), 'https://api.resend.com/emails');
    expect(captured!.headers['Authorization'], 'Bearer re_test_key');
    expect(captured!.headers['Content-Type'], contains('application/json'));
    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['from'], 'no-reply@vonlan233.top');
    expect(body['to'], ['user@example.com']);
    expect(body['subject'], 'Your LinguaQuest verification code');
    expect(body['text'], contains('123456'));
  });

  test('does not throw on a 2xx response', () async {
    final client = MockClient((req) async => http.Response('{"id":"x"}', 200));
    final sender = ResendEmailSender(
      _base.copyWith(resendApiKey: 're_test_key'),
      client: client,
    );
    await sender.sendVerificationCode(to: 'a@b.com', code: '654321');
  });

  test('throws with the status code on a non-2xx response', () async {
    final client = MockClient(
      (req) async => http.Response('{"message":"invalid from"}', 422),
    );
    final sender = ResendEmailSender(
      _base.copyWith(resendApiKey: 're_test_key'),
      client: client,
    );
    expect(
      () => sender.sendVerificationCode(to: 'a@b.com', code: '654321'),
      throwsA(predicate((e) => e.toString().contains('422'))),
    );
  });

  group('EmailSender.fromConfig selection', () {
    test('returns ResendEmailSender when resendApiKey is set', () {
      final sender = EmailSender.fromConfig(
        _base.copyWith(resendApiKey: 're_x', smtpHost: 'smtp.example.com'),
      );
      expect(sender, isA<ResendEmailSender>());
    });

    test('returns SmtpEmailSender when only smtpHost is set', () {
      final sender =
          EmailSender.fromConfig(_base.copyWith(smtpHost: 'smtp.example.com'));
      expect(sender, isA<SmtpEmailSender>());
    });

    test('returns ConsoleEmailSender when neither is set', () {
      final sender = EmailSender.fromConfig(_base);
      expect(sender, isA<ConsoleEmailSender>());
    });
  });
}
