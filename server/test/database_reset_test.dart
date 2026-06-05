import 'package:linguaquest_server/src/database.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('resetCustomWordProgress persists a bulk custom word reset', () async {
    final connection = _RecordingConnection();
    final database = AppDatabase(connection);
    final resetAt = DateTime.utc(2026, 6, 4, 9, 30);

    await database.resetCustomWordProgress('reset-user', now: resetAt);

    expect(resetCustomWordProgressSql, contains('UPDATE custom_words'));
    expect(resetCustomWordProgressSql, contains('mastery_level=0'));
    expect(resetCustomWordProgressSql, contains('correct_count=0'));
    expect(resetCustomWordProgressSql, contains('wrong_count=0'));
    expect(resetCustomWordProgressSql, contains('next_review_at=@resetAt'));
    expect(resetCustomWordProgressSql, contains('updated_at=@resetAt'));
    expect(resetCustomWordProgressSql, contains('WHERE uid=@uid'));
    expect(connection.lastQuery, isA<Sql>());
    expect(connection.lastParameters, {
      'uid': 'reset-user',
      'resetAt': resetAt,
    });
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
