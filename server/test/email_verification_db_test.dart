import 'package:linguaquest_server/src/database.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('setEmailVerified SQL + params', () async {
    final connection = _RecordingConnection();
    final database = AppDatabase(connection);
    await database.setEmailVerified('user-1');
    expect(setEmailVerifiedSql, contains('UPDATE users'));
    expect(setEmailVerifiedSql, contains('email_verified=TRUE'));
    expect(setEmailVerifiedSql, contains('WHERE id=@uid'));
    expect((connection.lastParameters as Map)['uid'], 'user-1');
  });

  test('upsertVerificationCode SQL + params', () async {
    final connection = _RecordingConnection();
    final database = AppDatabase(connection);
    final expires = DateTime.utc(2026, 6, 19, 10);
    final sent = DateTime.utc(2026, 6, 19, 9, 50);
    await database.upsertVerificationCode('user-1',
        codeHash: 'H', codeSalt: 'S', expiresAt: expires, sentAt: sent);
    expect(upsertVerificationCodeSql,
        contains('INSERT INTO email_verification_codes'));
    expect(
        upsertVerificationCodeSql, contains('ON CONFLICT (uid) DO UPDATE'));
    expect(upsertVerificationCodeSql, contains('attempts=0'));
    expect(connection.lastParameters, {
      'uid': 'user-1',
      'codeHash': 'H',
      'codeSalt': 'S',
      'expiresAt': expires,
      'sentAt': sent,
    });
  });

  test('incrementVerificationAttempts SQL + params', () async {
    final connection = _RecordingConnection();
    final database = AppDatabase(connection);
    await database.incrementVerificationAttempts('user-1');
    expect(incrementVerificationAttemptsSql, contains('attempts=attempts+1'));
    expect((connection.lastParameters as Map)['uid'], 'user-1');
  });

  test('deleteVerificationCode SQL + params', () async {
    final connection = _RecordingConnection();
    final database = AppDatabase(connection);
    await database.deleteVerificationCode('user-1');
    expect(deleteVerificationCodeSql,
        contains('DELETE FROM email_verification_codes'));
    expect((connection.lastParameters as Map)['uid'], 'user-1');
  });
}

class _RecordingConnection implements Connection {
  Object? lastQuery;
  Object? lastParameters;

  @override
  Future<Result> execute(
    Object query, {
    Object? parameters,
    bool ignoreRows = false,
    QueryMode? queryMode,
    Duration? timeout,
  }) async {
    lastQuery = query;
    lastParameters = parameters;
    return Result(rows: const [], affectedRows: 0, schema: ResultSchema([]));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
