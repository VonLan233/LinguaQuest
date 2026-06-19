import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/email_sender.dart';
import 'package:test/test.dart';

void main() {
  test('ConsoleEmailSender records the code it would send', () async {
    final sender = ConsoleEmailSender();
    await sender.sendVerificationCode(to: 'a@b.co', code: '123456');
    expect(sender.lastTo, 'a@b.co');
    expect(sender.lastCode, '123456');
  });

  test('fromConfig uses console when SMTP host is empty', () {
    const config = AppConfig(port: 0, databaseUrl: 'x', jwtSecret: 'y');
    expect(EmailSender.fromConfig(config), isA<ConsoleEmailSender>());
  });

  test('fromConfig uses SMTP when host is set', () {
    const config = AppConfig(
      port: 0,
      databaseUrl: 'x',
      jwtSecret: 'y',
      smtpHost: 'smtp.example.com',
    );
    expect(EmailSender.fromConfig(config), isA<SmtpEmailSender>());
  });
}
