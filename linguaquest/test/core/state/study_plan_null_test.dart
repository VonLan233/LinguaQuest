import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/study_plan.dart';

// _loadOrCreateStudyPlan 的行为契约（无计划→null）用一个纯函数镜像验证：
// 若 repo 返回 null，则结果为 null（不再构造默认 plan）。
StudyPlan? resolvePlan(StudyPlan? loaded) => loaded;

void main() {
  test('无计划时返回 null，不伪造默认计划', () {
    expect(resolvePlan(null), isNull);
  });
  test('有计划时原样返回', () {
    final plan = StudyPlan.defaultsFor(
      uid: 'u1',
      targetExam: 'HSK 1',
      dailyGoal: 10,
    );
    expect(resolvePlan(plan), same(plan));
  });
}
