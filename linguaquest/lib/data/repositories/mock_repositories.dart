import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/custom_word.dart';
import '../models/daily_reward_task.dart';
import '../models/exercise_record.dart';
import '../models/lesson.dart';
import '../models/lottery.dart';
import '../models/point_grant_result.dart';
import '../models/review_event.dart';
import '../models/study_session.dart';
import '../models/study_plan.dart';
import '../models/user_word.dart';
import '../models/user_profile.dart';
import '../lesson_factory.dart';
import '../wordbook_asset_loader.dart';
import 'auth_repository.dart';
import 'custom_word_repository.dart';
import 'learning_repository.dart';
import 'lottery_repository.dart';
import 'notification_repository.dart';
import 'reward_repository.dart';
import 'reward_task_repository.dart';
import 'review_repository.dart';
import 'study_plan_repository.dart';
import 'user_word_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const _profileKey = 'linguaquest.profile';
  static const _registeredEmailsKey = 'linguaquest.mock.registered_emails';
  UserProfile? _profile;

  @override
  Future<UserProfile?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) {
      _profile = null;
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      _profile = UserProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await prefs.remove(_profileKey);
      return null;
    }
    return _profile;
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final registeredEmails =
        prefs.getStringList(_registeredEmailsKey) ?? const <String>[];
    final normalizedRegisteredEmails = registeredEmails
        .map((email) => email.trim().toLowerCase())
        .toSet();
    if (normalizedRegisteredEmails.contains(normalizedEmail)) {
      throw StateError('email already registered');
    }
    final now = DateTime.now();
    final profile = UserProfile(
      uid: 'user-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      targetExam: 'HSK 1',
      level: 'Beginner',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    await prefs.setStringList(_registeredEmailsKey, [
      ...normalizedRegisteredEmails,
      normalizedEmail,
    ]);
    return updateProfile(profile);
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final existing = await loadSession();
    if (existing != null && existing.email == email.trim().toLowerCase()) {
      return existing;
    }
    final profile = UserProfile.demo().copyWith(
      email: email.trim().toLowerCase(),
      updatedAt: DateTime.now(),
    );
    return updateProfile(profile);
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    return profile;
  }

  @override
  Future<void> logout() async {
    _profile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}

class MockCustomWordRepository implements CustomWordRepository {
  final List<CustomWord> _words = [];

  @override
  Future<List<CustomWord>> list(String uid) async {
    if (_words.where((word) => word.uid == uid).isEmpty) {
      _seed(uid);
    }
    final scoped = _words.where((word) => word.uid == uid).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return scoped;
  }

  @override
  Future<CustomWord> create(CustomWord word) async {
    _words.add(word);
    return word;
  }

  @override
  Future<void> delete(String uid, String id) async {
    _words.removeWhere((word) => word.uid == uid && word.id == id);
  }

  @override
  Future<CustomWord> update(CustomWord word) async {
    final index = _words.indexWhere(
      (item) => item.uid == word.uid && item.id == word.id,
    );
    if (index == -1) {
      _words.add(word);
    } else {
      _words[index] = word;
    }
    return word;
  }

  void _seed(String uid) {
    final now = DateTime.now();
    _words.addAll([
      CustomWord.create(
        id: 'seed-1',
        uid: uid,
        word: '你好',
        meaning: 'hello',
        exampleSentence: '',
        note: 'A common greeting.',
        tag: 'character',
        difficulty: 'Easy',
        now: now.subtract(const Duration(days: 1)),
        definitions: const ['hello'],
        englishDefinitions: const ['hello; hi'],
        malayDefinitions: const ['helo'],
      ).copyWith(masteryLevel: 2, correctCount: 3, wrongCount: 1),
      CustomWord.create(
        id: 'seed-2',
        uid: uid,
        word: '谢谢',
        meaning: 'thanks',
        exampleSentence: '',
        note: 'Used to express gratitude.',
        tag: 'character',
        difficulty: 'Easy',
        now: now.subtract(const Duration(days: 2)),
        definitions: const ['thanks'],
        englishDefinitions: const ['thank you; thanks'],
        malayDefinitions: const ['terima kasih'],
      ).copyWith(
        masteryLevel: 1,
        correctCount: 1,
        wrongCount: 3,
        nextReviewAt: now,
      ),
    ]);
  }
}

class MockLearningRepository implements LearningRepository {
  MockLearningRepository({WordBookAssetLoader? loader})
    : _loader = loader ?? WordBookAssetLoader();

  final WordBookAssetLoader _loader;
  final List<StudySession> _sessions = [];
  final List<ExerciseRecord> _exerciseRecords = [];

  @override
  Future<List<WordBook>> listWordBooks() => _loader.loadWordBooks();

  @override
  Future<List<Lesson>> listLessons() async {
    final books = await listWordBooks();
    if (books.isEmpty) return const [];
    return listLessonsForWordBook(books.first.id);
  }

  @override
  Future<List<Lesson>> listLessonsForWordBook(String wordBookId) async {
    final books = await listWordBooks();
    if (books.isEmpty) return const [];
    final book = _bookById(books, wordBookId) ?? books.first;
    return lessonsFromWordBook(book);
  }

  @override
  Future<LearningProgress?> loadLearningProgress(DateTime now) async => null;

  @override
  Future<void> recordStudySession(StudySession session) async {
    _sessions.add(session);
  }

  @override
  Future<void> recordExerciseRecords(List<ExerciseRecord> records) async {
    _exerciseRecords.addAll(records);
  }

  @override
  Future<RewardClaimResult?> claimReward({
    required String id,
    required int points,
    required DateTime now,
  }) async {
    return null;
  }

  WordBook? _bookById(List<WordBook> books, String id) {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }
}

class MockUserWordRepository implements UserWordRepository {
  static const _keyPrefix = 'linguaquest.user_words';
  final Map<String, List<UserWord>> _cache = {};

  @override
  Future<List<UserWord>> list(String uid) async {
    if (_cache[uid] != null) return _sorted(_cache[uid]!);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix.$uid');
    if (raw == null) {
      _cache[uid] = [];
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _cache[uid] = [];
        return [];
      }
      final words = decoded
          .whereType<Map>()
          .map((item) => UserWord.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _cache[uid] = words;
      return _sorted(words);
    } catch (_) {
      await prefs.remove('$_keyPrefix.$uid');
      _cache[uid] = [];
      return [];
    }
  }

  @override
  Future<UserWord> upsert(UserWord word) async {
    final updated = (await upsertAll([word])).first;
    return updated;
  }

  @override
  Future<List<UserWord>> upsertAll(List<UserWord> words) async {
    if (words.isEmpty) return [];
    final uid = words.first.uid;
    final existing = await list(uid);
    final byId = {for (final word in existing) word.id: word};
    for (final word in words) {
      byId[word.id] = word;
    }
    final merged = _sorted(byId.values.toList());
    _cache[uid] = merged;
    await _save(uid, merged);
    return words;
  }

  Future<void> _save(String uid, List<UserWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix.$uid',
      jsonEncode([for (final word in words) word.toJson()]),
    );
  }

  List<UserWord> _sorted(List<UserWord> words) {
    return [...words]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}

class MockStudyPlanRepository implements StudyPlanRepository {
  static const _keyPrefix = 'linguaquest.studyPlan';

  @override
  Future<StudyPlan?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix.$uid');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return StudyPlan.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await prefs.remove('$_keyPrefix.$uid');
      return null;
    }
  }

  @override
  Future<StudyPlan> save(StudyPlan plan) async {
    final normalized = plan.copyWith(updatedAt: DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix.${normalized.uid}',
      jsonEncode(normalized.toJson()),
    );
    return normalized;
  }

  @override
  Future<StudyPlan> reset(StudyPlan plan) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetFinishDate = plan.targetFinishDate.isBefore(today)
        ? today.add(const Duration(days: 30))
        : plan.targetFinishDate;
    return save(
      plan.copyWith(
        startDate: today,
        targetFinishDate: targetFinishDate,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }
}

class MockReviewRepository implements ReviewRepository {
  final List<ReviewEvent> _events = [];

  @override
  Future<void> recordReviewEvent(ReviewEvent event) async {
    _events.add(event);
  }
}

class MockNotificationRepository implements NotificationRepository {
  static const _keyPrefix = 'linguaquest.notifications';

  @override
  Future<void> ensureGenerated(
    String uid,
    List<AppNotification> notifications,
  ) async {
    if (notifications.isEmpty) return;
    final existing = await _load(uid);
    final sourceKeys = existing
        .map((notification) => notification.sourceKey)
        .whereType<String>()
        .toSet();
    final ids = existing.map((notification) => notification.id).toSet();
    final merged = [...existing];
    for (final notification in notifications) {
      final sourceKey = notification.sourceKey;
      if (sourceKey != null && sourceKeys.contains(sourceKey)) continue;
      if (ids.contains(notification.id)) continue;
      merged.add(notification);
      if (sourceKey != null) sourceKeys.add(sourceKey);
      ids.add(notification.id);
    }
    await _save(uid, merged);
  }

  @override
  Future<List<AppNotification>> list(
    String uid, {
    bool unreadOnly = false,
    AppNotificationType? type,
  }) async {
    final notifications = await _load(uid);
    return notifications.where((notification) {
      if (unreadOnly && notification.isRead) return false;
      if (type != null && notification.type != type) return false;
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> markAllRead(String uid) async {
    final now = DateTime.now();
    final existing = await _load(uid);
    final updated = existing
        .where((notification) => !notification.isRead)
        .length;
    final notifications = [
      for (final notification in existing)
        if (notification.isRead)
          notification
        else
          notification.markRead(now: now),
    ];
    await _save(uid, notifications);
    return updated;
  }

  @override
  Future<AppNotification?> markRead(String uid, String id) async {
    final now = DateTime.now();
    AppNotification? updated;
    final notifications = [
      for (final notification in await _load(uid))
        if (notification.id == id)
          updated = notification.markRead(now: now)
        else
          notification,
    ];
    await _save(uid, notifications);
    return updated;
  }

  Future<List<AppNotification>> _load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix.$uid');
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      await prefs.remove('$_keyPrefix.$uid');
      return [];
    }
  }

  Future<void> _save(String uid, List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = [...notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await prefs.setString(
      '$_keyPrefix.$uid',
      jsonEncode([for (final notification in sorted) notification.toJson()]),
    );
  }
}

class MockLotteryRepository implements LotteryRepository {
  static const _assetKeyPrefix = 'linguaquest.assets';
  static const _profileKey = 'linguaquest.profile';
  final Random _random = Random();

  @override
  Future<List<LotteryPrize>> prizePool() async => _mockPrizePool;

  @override
  Future<List<UserAsset>> assets(String uid) async {
    final assets = await _loadAssets(uid);
    return assets..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<LotteryDrawResponse> draw({
    required String uid,
    required int currentXp,
  }) async {
    if (currentXp < lotteryDrawCost) {
      throw StateError('not enough XP for this draw');
    }
    final now = DateTime.now().toUtc();
    final prize = _choosePrize(_mockPrizePool);
    final existing = await _loadAssets(uid);
    final index = existing.indexWhere((asset) => asset.prizeId == prize.id);
    final asset = index == -1
        ? UserAsset(
            id: 'asset-${now.microsecondsSinceEpoch}',
            uid: uid,
            prizeId: prize.id,
            category: prize.category,
            rarity: prize.rarity,
            name: prize.name,
            description: prize.description,
            quantity: 1,
            fragmentValue: prize.fragmentValue,
            acquiredAt: now,
            updatedAt: now,
          )
        : UserAsset(
            id: existing[index].id,
            uid: existing[index].uid,
            prizeId: existing[index].prizeId,
            category: prize.category,
            rarity: prize.rarity,
            name: prize.name,
            description: prize.description,
            quantity: existing[index].quantity + 1,
            fragmentValue: prize.fragmentValue,
            acquiredAt: existing[index].acquiredAt,
            updatedAt: now,
          );
    final updatedAssets = [...existing];
    if (index == -1) {
      updatedAssets.add(asset);
    } else {
      updatedAssets[index] = asset;
    }
    await _saveAssets(uid, updatedAssets);
    final updatedUser = await _deductProfileXp(
      uid: uid,
      balanceAfter: currentXp - lotteryDrawCost,
      now: now,
    );
    return LotteryDrawResponse(
      result: LotteryDrawResult(
        drawId: 'draw-${now.microsecondsSinceEpoch}',
        prize: prize,
        asset: asset,
        cost: lotteryDrawCost,
        balanceAfter: currentXp - lotteryDrawCost,
        createdAt: now,
      ),
      user: updatedUser,
      notifications: [
        AppNotification(
          id: 'lottery-${now.microsecondsSinceEpoch}',
          uid: uid,
          type: AppNotificationType.activity,
          title: '积分抽奖结果',
          body: '获得「${prize.name}」，已放入个人资产。',
          targetRoute: '/profile',
          isRead: false,
          createdAt: now,
          sourceKey: 'lottery:${now.microsecondsSinceEpoch}',
          params: {'kind': 'lottery', 'prizeName': prize.name},
        ),
      ],
    );
  }

  Future<UserProfile?> _deductProfileXp({
    required String uid,
    required int balanceAfter,
    required DateTime now,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await prefs.remove(_profileKey);
        return null;
      }
      final profile = UserProfile.fromJson(Map<String, dynamic>.from(decoded));
      if (profile.uid != uid) return null;
      final updated = profile.copyWith(xp: balanceAfter, updatedAt: now);
      await prefs.setString(_profileKey, jsonEncode(updated.toJson()));
      return updated;
    } catch (_) {
      await prefs.remove(_profileKey);
      return null;
    }
  }

  LotteryPrize _choosePrize(List<LotteryPrize> prizes) {
    final total = prizes.fold<double>(
      0,
      (sum, prize) => sum + prize.probability,
    );
    final roll = _random.nextDouble() * total;
    var cursor = 0.0;
    for (final prize in prizes) {
      cursor += prize.probability;
      if (roll <= cursor) return prize;
    }
    return prizes.last;
  }

  Future<List<UserAsset>> _loadAssets(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_assetKeyPrefix.$uid');
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => UserAsset.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      await prefs.remove('$_assetKeyPrefix.$uid');
      return [];
    }
  }

  Future<void> _saveAssets(String uid, List<UserAsset> assets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_assetKeyPrefix.$uid',
      jsonEncode([for (final asset in assets) asset.toJson()]),
    );
  }
}

const _mockPrizePool = [
  LotteryPrize(
    id: 'avatar-frame-starry',
    name: '星轨头像框',
    category: 'avatarFrame',
    rarity: 'rare',
    description: '围绕头像的星轨装饰，不提供学习分数加成。',
    probability: 6,
    fragmentValue: 18,
  ),
  LotteryPrize(
    id: 'profile-bg-aurora',
    name: '极光主页背景',
    category: 'profileBackground',
    rarity: 'rare',
    description: '个人空间可展示的极光背景，不影响学习公平性。',
    probability: 7,
    fragmentValue: 16,
  ),
  LotteryPrize(
    id: 'badge-focus-sprinter',
    name: '专注冲刺徽章',
    category: 'badge',
    rarity: 'uncommon',
    description: '学习资料页展示徽章，仅作荣誉装饰。',
    probability: 16,
    fragmentValue: 8,
  ),
  LotteryPrize(
    id: 'title-arena-scout',
    name: '训练场侦察员称号',
    category: 'title',
    rarity: 'uncommon',
    description: '训练场称号展示，不提高答题分数。',
    probability: 14,
    fragmentValue: 8,
  ),
  LotteryPrize(
    id: 'card-skin-mint',
    name: '薄荷卡片皮肤',
    category: 'cardSkin',
    rarity: 'common',
    description: '单词卡片视觉皮肤，不改变记忆算法。',
    probability: 22,
    fragmentValue: 5,
  ),
  LotteryPrize(
    id: 'comfort-star-fragments',
    name: '星尘碎片',
    category: 'fragment',
    rarity: 'comfort',
    description: '安慰奖励，可累计兑换装饰资产。',
    probability: 35,
    fragmentValue: 3,
  ),
];

class MockRewardTaskRepository implements RewardTaskRepository {
  static const _keyPrefix = 'linguaquest.rewards';

  @override
  Future<RewardTaskSnapshot> listTasks(String uid) async {
    return _snapshot(uid);
  }

  @override
  Future<RewardTaskSnapshot> checkIn(String uid) async {
    final state = await _load(uid);
    state.checkedIn = true;
    await _save(uid, state);
    return _snapshot(uid);
  }

  @override
  Future<RewardTaskSnapshot> claimTask(String uid, String taskId) async {
    final state = await _load(uid);
    final tasks = _tasksFor(state);
    DailyRewardTask? task;
    for (final item in tasks) {
      if (item.id == taskId) {
        task = item;
        break;
      }
    }
    if (task == null || task.isClaimed) {
      final snapshot = await _snapshot(uid);
      return RewardTaskSnapshot(
        dateKey: snapshot.dateKey,
        tasks: snapshot.tasks,
        alreadyClaimed: task?.isClaimed == true,
        claimed: false,
      );
    }
    if (!task.isClaimable) return _snapshot(uid);
    state.claimedTaskIds.add(taskId);
    await _save(uid, state);
    final snapshot = await _snapshot(uid);
    return RewardTaskSnapshot(
      dateKey: snapshot.dateKey,
      tasks: snapshot.tasks,
      claimed: true,
    );
  }

  @override
  Future<RewardTaskSnapshot> recordEvent(
    String uid,
    RewardEventType type,
  ) async {
    final state = await _load(uid);
    switch (type) {
      case RewardEventType.newLearning:
        state.newLearningDone = true;
      case RewardEventType.reviewDone:
        state.reviewDone = true;
      case RewardEventType.trainingChallenge:
        state.trainingChallengeDone = true;
      case RewardEventType.wrongCleanup:
        state.reviewDone = true;
        state.wrongCleanupDone = true;
      case RewardEventType.forumInteraction:
        state.forumInteractionDone = true;
    }
    await _save(uid, state);
    return _snapshot(uid);
  }

  Future<RewardTaskSnapshot> _snapshot(String uid) async {
    final state = await _load(uid);
    return RewardTaskSnapshot(dateKey: state.dateKey, tasks: _tasksFor(state));
  }

  List<DailyRewardTask> _tasksFor(_MockRewardState state) {
    return [
      _task(
        id: 'dailyCheckIn',
        title: '每日签到',
        condition: '当天打开并点击签到',
        points: 5,
        targetRoute: '/discover',
        done: state.checkedIn,
        claimed: state.claimedTaskIds.contains('dailyCheckIn'),
      ),
      _task(
        id: 'newLearning',
        title: '完成新学',
        condition: '完成今日新学任务',
        points: 20,
        targetRoute: '/study/new',
        done: state.newLearningDone,
        claimed: state.claimedTaskIds.contains('newLearning'),
      ),
      _task(
        id: 'reviewDone',
        title: '完成复习',
        condition: '完成今日到期复习',
        points: 15,
        targetRoute: '/study/review',
        done: state.reviewDone,
        claimed: state.claimedTaskIds.contains('reviewDone'),
      ),
      _task(
        id: 'trainingChallenge',
        title: '训练场挑战',
        condition: '完成任意训练场游戏',
        points: 20,
        targetRoute: '/training',
        done: state.trainingChallengeDone,
        claimed: state.claimedTaskIds.contains('trainingChallenge'),
      ),
      _task(
        id: 'wrongCleanup',
        title: '错词清理',
        condition: '今日错词再次答对',
        points: 10,
        targetRoute: '/review',
        done: state.wrongCleanupDone,
        claimed: state.claimedTaskIds.contains('wrongCleanup'),
      ),
      _task(
        id: 'forumInteraction',
        title: '论坛互动',
        condition: '发帖或评论通过审核',
        points: 5,
        targetRoute: '/discover',
        done: state.forumInteractionDone,
        claimed: state.claimedTaskIds.contains('forumInteraction'),
      ),
    ];
  }

  DailyRewardTask _task({
    required String id,
    required String title,
    required String condition,
    required int points,
    required String targetRoute,
    required bool done,
    required bool claimed,
  }) {
    return DailyRewardTask(
      id: id,
      title: title,
      condition: condition,
      points: points,
      targetRoute: targetRoute,
      status: claimed
          ? DailyRewardTaskStatus.claimed
          : done
          ? DailyRewardTaskStatus.claimable
          : DailyRewardTaskStatus.incomplete,
    );
  }

  Future<_MockRewardState> _load(String uid) async {
    final todayKey = _dateKey(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix.$uid');
    if (raw == null) return _MockRewardState(dateKey: todayKey);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return _MockRewardState(dateKey: todayKey);
      final state = _MockRewardState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return state.dateKey == todayKey
          ? state
          : _MockRewardState(dateKey: todayKey);
    } catch (_) {
      await prefs.remove('$_keyPrefix.$uid');
      return _MockRewardState(dateKey: todayKey);
    }
  }

  Future<void> _save(String uid, _MockRewardState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix.$uid', jsonEncode(state.toJson()));
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _MockRewardState {
  _MockRewardState({required this.dateKey});

  final String dateKey;
  bool checkedIn = false;
  bool newLearningDone = false;
  bool reviewDone = false;
  bool trainingChallengeDone = false;
  bool wrongCleanupDone = false;
  bool forumInteractionDone = false;
  final Set<String> claimedTaskIds = <String>{};

  factory _MockRewardState.fromJson(Map<String, dynamic> json) {
    return _MockRewardState(dateKey: json['dateKey'] as String? ?? '')
      ..checkedIn = json['checkedIn'] == true
      ..newLearningDone = json['newLearningDone'] == true
      ..reviewDone = json['reviewDone'] == true
      ..trainingChallengeDone = json['trainingChallengeDone'] == true
      ..wrongCleanupDone = json['wrongCleanupDone'] == true
      ..forumInteractionDone = json['forumInteractionDone'] == true
      ..claimedTaskIds.addAll(
        (json['claimedTaskIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>(),
      );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'checkedIn': checkedIn,
      'newLearningDone': newLearningDone,
      'reviewDone': reviewDone,
      'trainingChallengeDone': trainingChallengeDone,
      'wrongCleanupDone': wrongCleanupDone,
      'forumInteractionDone': forumInteractionDone,
      'claimedTaskIds': claimedTaskIds.toList(),
    };
  }
}

class MockRewardRepository implements RewardRepository {
  static const _grantedSourceKeys = 'linguaquest.mock.point_sources';

  @override
  Future<PointGrantResult> grantPoints({
    required String uid,
    required String sourceType,
    required String sourceId,
    required int points,
    required String description,
  }) async {
    if (points <= 0) {
      return const PointGrantResult(pointsAwarded: 0, alreadyGranted: false);
    }
    final prefs = await SharedPreferences.getInstance();
    final key = '$uid::$sourceType::$sourceId';
    final granted =
        (prefs.getStringList(_grantedSourceKeys) ?? const <String>[]).toSet();
    if (granted.contains(key)) {
      return const PointGrantResult(pointsAwarded: 0, alreadyGranted: true);
    }
    granted.add(key);
    await prefs.setStringList(_grantedSourceKeys, granted.toList());
    return PointGrantResult(pointsAwarded: points, alreadyGranted: false);
  }
}
