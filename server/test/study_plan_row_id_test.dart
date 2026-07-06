import 'package:linguaquest_server/src/database.dart';
import 'package:test/test.dart';

void main() {
  group('studyPlanRowId', () {
    test('reuses the existing scope row id (ON CONFLICT updates that row)', () {
      expect(studyPlanRowId({'id': 'existing-123'}), 'existing-123');
    });

    test('mints a fresh id for a new scope — never reuses a client-sent id', () {
      // Regression: switching to a new (language, wordbook) scope used to reuse
      // the client's CURRENT plan id, colliding with study_plans_pkey → 500.
      final id = studyPlanRowId(null);
      expect(id, isNotEmpty);
      expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(id), isTrue, reason: id);
      // Genuinely fresh each call.
      expect(studyPlanRowId(null), isNot(equals(id)));
    });
  });
}
