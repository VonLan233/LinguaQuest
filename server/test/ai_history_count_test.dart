import 'package:linguaquest_server/src/database.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

void main() {
  test('countAiHistoryTodaySql targets today undeleted rows', () {
    expect(countAiHistoryTodaySql, contains('FROM ai_history'));
    expect(countAiHistoryTodaySql, contains('user_id=@userId'));
    expect(countAiHistoryTodaySql, contains('is_deleted=FALSE'));
    expect(countAiHistoryTodaySql, contains('CURRENT_DATE'));
  });

  test('countAiHistoryToday passes userId and returns the count', () async {
    final connection = _StubConnection(count: 7);
    final database = AppDatabase(connection);
    final result = await database.countAiHistoryToday('user-1');
    expect(result, equals(7));
    expect((connection.lastParameters as Map)['userId'], 'user-1');
  });

  test('countAiHistoryToday returns 0 when no rows', () async {
    final connection = _StubConnection(count: null);
    final database = AppDatabase(connection);
    final result = await database.countAiHistoryToday('user-2');
    expect(result, equals(0));
  });
}

/// Stub connection returning a single COUNT row (or no rows when count is null).
class _StubConnection implements Connection {
  _StubConnection({required this.count});

  final int? count;
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
    final schema = ResultSchema(const []);
    final rows = count == null
        ? const <ResultRow>[]
        : [
            ResultRow(
              schema: schema,
              values: [count],
            ),
          ];
    return Result(
      rows: rows,
      affectedRows: 0,
      schema: schema,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
