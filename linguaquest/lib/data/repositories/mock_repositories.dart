import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'profile_repository.dart';

import '../../core/utils/email_validation.dart';
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
import 'ai_repository.dart';
import 'analytics_repository.dart';
import 'auth_repository.dart';
import 'custom_word_repository.dart';
import '../models/achievement.dart';
import '../models/ai_feature.dart';
import '../models/analytics.dart';
import '../models/forum.dart';
import '../models/recommendation.dart';
import '../models/study_spot.dart';
import 'forum_repository.dart';
import 'learning_repository.dart';
import 'lottery_repository.dart';
import 'notification_repository.dart';
import 'reward_repository.dart';
import 'reward_task_repository.dart';
import 'review_repository.dart';
import 'study_plan_repository.dart';
import 'study_spot_repository.dart';
import 'user_word_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const _profileKey = 'linguaquest.profile';
  static const _registeredEmailsKey = 'linguaquest.mock.registered_emails';
  UserProfile? _profile;

  /// In offline/demo mode, any 6-digit all-digit code is accepted as correct.
  /// Passing any non-numeric or wrong-length value throws [EmailVerificationException]
  /// with reason 'invalid_code', so UI error paths can be exercised in tests.

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
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isValidEmail(normalizedEmail)) {
      throw StateError('invalid email');
    }
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
    return AuthSuccess(await updateProfile(profile));
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!isValidEmail(normalizedEmail)) {
      throw StateError('invalid email');
    }
    final prefs = await SharedPreferences.getInstance();
    final registered = (prefs.getStringList(_registeredEmailsKey) ?? const [])
        .map((e) => e.trim().toLowerCase())
        .toSet();
    final existing = await loadSession();
    if (existing != null && existing.email == normalizedEmail) {
      return existing;
    }
    if (!registered.contains(normalizedEmail)) {
      throw StateError('account not found');
    }
    final profile = UserProfile.demo().copyWith(
      email: normalizedEmail,
      updatedAt: DateTime.now(),
    );
    return updateProfile(profile);
  }

  @override
  Future<UserProfile> verifyEmail({
    required String email,
    required String code,
  }) async {
    // In demo/offline mode we accept any all-digit 6-character code.
    // Any other value simulates a wrong-code error so UI error-handling paths
    // can be exercised in unit tests.
    final trimmed = code.trim();
    final isNumeric = RegExp(r'^\d{6}$').hasMatch(trimmed);
    if (!isNumeric) {
      throw const EmailVerificationException('invalid_code');
    }
    final existing = await loadSession();
    if (existing != null) return existing;
    // Register was called earlier — look up the profile via the registered list.
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final registered = (prefs.getStringList(_registeredEmailsKey) ?? const [])
        .map((e) => e.trim().toLowerCase())
        .toSet();
    if (!registered.contains(normalizedEmail)) {
      throw StateError('account not found');
    }
    final profile = UserProfile.demo().copyWith(
      email: normalizedEmail,
      updatedAt: DateTime.now(),
    );
    return updateProfile(profile);
  }

  @override
  // In offline/demo mode resendCode is a no-op — the mock OTP is always
  // accepted, so there is nothing to re-issue.
  Future<void> resendCode(String email) async {}

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
    probability: 4,
    fragmentValue: 18,
  ),
  LotteryPrize(
    id: 'avatar-frame-ember',
    name: '烬焰头像框',
    category: 'avatarFrame',
    rarity: 'rare',
    description: '燃烧余烬风格头像框，不影响学习公平性。',
    probability: 3,
    fragmentValue: 18,
  ),
  LotteryPrize(
    id: 'profile-bg-aurora',
    name: '极光主页背景',
    category: 'profileBackground',
    rarity: 'rare',
    description: '个人空间可展示的极光背景，不影响学习公平性。',
    probability: 4,
    fragmentValue: 16,
  ),
  LotteryPrize(
    id: 'profile-bg-dawn-harbor',
    name: '黎明港湾背景',
    category: 'profileBackground',
    rarity: 'rare',
    description: '黎明港口风景背景，仅作装饰展示。',
    probability: 3,
    fragmentValue: 16,
  ),
  LotteryPrize(
    id: 'badge-focus-sprinter',
    name: '专注冲刺徽章',
    category: 'badge',
    rarity: 'uncommon',
    description: '学习资料页展示徽章，仅作荣誉装饰。',
    probability: 9,
    fragmentValue: 8,
  ),
  LotteryPrize(
    id: 'badge-night-owl',
    name: '夜枭徽章',
    category: 'badge',
    rarity: 'uncommon',
    description: '深夜学习者专属徽章，不提高答题分数。',
    probability: 7,
    fragmentValue: 8,
  ),
  LotteryPrize(
    id: 'badge-anniversary-lantern',
    name: '周年灯笼徽章',
    category: 'badge',
    rarity: 'rare',
    description: '特别活动限定徽章，仅作荣誉纪念。',
    probability: 2,
    fragmentValue: 20,
  ),
  LotteryPrize(
    id: 'title-arena-scout',
    name: '训练场侦察员称号',
    category: 'title',
    rarity: 'uncommon',
    description: '训练场称号展示，不提高答题分数。',
    probability: 8,
    fragmentValue: 8,
  ),
  LotteryPrize(
    id: 'title-lexicon-keeper',
    name: '词汇守护者称号',
    category: 'title',
    rarity: 'uncommon',
    description: '词汇学习者称号，不影响学习公平性。',
    probability: 7,
    fragmentValue: 8,
  ),
  LotteryPrize(
    id: 'title-dawn-voyager',
    name: '黎明航行者称号',
    category: 'title',
    rarity: 'rare',
    description: '稀有探索者称号，仅作装饰。',
    probability: 3,
    fragmentValue: 16,
  ),
  LotteryPrize(
    id: 'card-skin-mint',
    name: '薄荷卡片皮肤',
    category: 'cardSkin',
    rarity: 'common',
    description: '单词卡片视觉皮肤，不改变记忆算法。',
    probability: 12,
    fragmentValue: 5,
  ),
  LotteryPrize(
    id: 'card-skin-sakura',
    name: '樱花卡片皮肤',
    category: 'cardSkin',
    rarity: 'common',
    description: '樱花风格卡片皮肤，不改变记忆算法。',
    probability: 11,
    fragmentValue: 5,
  ),
  LotteryPrize(
    id: 'card-skin-midnight',
    name: '午夜卡片皮肤',
    category: 'cardSkin',
    rarity: 'common',
    description: '深色午夜风格卡片皮肤，不影响学习成绩。',
    probability: 10,
    fragmentValue: 5,
  ),
  LotteryPrize(
    id: 'card-skin-citrus',
    name: '柑橘卡片皮肤',
    category: 'cardSkin',
    rarity: 'common',
    description: '清新柑橘色调卡片皮肤，仅作视觉装饰。',
    probability: 7,
    fragmentValue: 4,
  ),
  LotteryPrize(
    id: 'comfort-star-fragments',
    name: '星尘碎片',
    category: 'fragment',
    rarity: 'comfort',
    description: '安慰奖励，可累计兑换装饰资产。',
    probability: 10,
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

class MockAiRepository implements AiRepository {
  final List<AiHistoryEntry> _history = [];
  int _idCounter = 0;

  @override
  Future<Map<String, dynamic>> chat({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    final snippet = prompt.length > 30 ? prompt.substring(0, 30) : prompt;
    final result = <String, dynamic>{
      'answer': 'Mock answer for: $snippet',
      'cautions': <String>[],
      'relatedWords': <String>[],
    };
    _history.insert(
      0,
      AiHistoryEntry(
        id: 'mock-${_idCounter++}',
        featureType: 'chat',
        prompt: prompt,
        response: result,
        createdAt: DateTime.now(),
      ),
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>> analyzeStatement({
    required String prompt,
    required String targetLanguage,
  }) async {
    final result = <String, dynamic>{
      'mainClause': 'Mock main clause',
      'clauses': <String>[],
      'modifiers': <String>[],
      'translation': 'Mock translation',
      'vocabularyNotes': <String>[],
    };
    _history.insert(
      0,
      AiHistoryEntry(
        id: 'mock-${_idCounter++}',
        featureType: 'sentence_analysis',
        prompt: prompt,
        response: result,
        createdAt: DateTime.now(),
      ),
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>> generateCloze({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    final word = targetWord ?? 'word';
    final result = <String, dynamic>{
      'passage': 'The ___ was very interesting.',
      'blanks': [
        {
          'index': 0,
          'answer': word,
          'options': [word, 'thing', 'idea', 'place'],
        },
      ],
      'explanations': <String>[],
    };
    _history.insert(
      0,
      AiHistoryEntry(
        id: 'mock-${_idCounter++}',
        featureType: 'cloze',
        prompt: prompt,
        response: result,
        createdAt: DateTime.now(),
      ),
    );
    return result;
  }

  @override
  Future<List<AiHistoryEntry>> listHistory() async {
    return List.unmodifiable(_history);
  }

  @override
  Future<void> deleteHistory(String id) async {
    _history.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<Map<String, dynamic>> reviewWriting({
    required String essay,
    required String targetLanguage,
    String? examType,
    double? targetScore,
  }) async {
    final result = <String, dynamic>{
      'totalScore': 75,
      'rubricScores': <String, int>{
        'content': 18,
        'language': 15,
        'structure': 14,
        'vocabulary': 15,
        'accuracy': 13,
      },
      'mainIssues': <String>['Limited vocabulary variety'],
      'paragraphSuggestions': <Map<String, String>>[],
      'highScoreExpressions': <String>[
        'Furthermore, it is worth noting that...',
      ],
      'grammarIssues': <Map<String, String>>[],
      'rewrittenSample': 'Mock rewritten sample.',
    };
    _history.insert(
      0,
      AiHistoryEntry(
        id: 'mock-wr-${_idCounter++}',
        featureType: 'writing_review',
        prompt: essay,
        response: result,
        createdAt: DateTime.now(),
      ),
    );
    return result;
  }
}

class MockForumRepository implements ForumRepository {
  final List<ForumPost> _posts = _buildSeedPosts();

  final Map<String, List<ForumComment>> _comments = {};
  final Set<String> _likedPostIds = {};
  final Set<String> _favoritedPostIds = {};
  int _postIdCounter = 10;
  int _commentIdCounter = 100;

  @override
  Future<List<ForumPost>> listPosts() async {
    return _posts
        .map(
          (post) => post.copyWith(
            isLiked: _likedPostIds.contains(post.id),
            isFavorited: _favoritedPostIds.contains(post.id),
          ),
        )
        .toList();
  }

  @override
  Future<ForumPost> getPost(String id) async {
    final post = _posts.firstWhere(
      (post) => post.id == id,
      orElse: () => throw StateError('post not found: $id'),
    );
    return post.copyWith(
      isLiked: _likedPostIds.contains(id),
      isFavorited: _favoritedPostIds.contains(id),
    );
  }

  @override
  Future<ForumPost> createPost({
    required String title,
    required String body,
    required String tag,
  }) async {
    final id = 'mock-post-${++_postIdCounter}';
    final post = ForumPost(
      id: id,
      authorId: 'current-user',
      authorName: 'You',
      title: title,
      body: body,
      tag: tag,
      status: 'approved',
      likeCount: 0,
      commentCount: 0,
      isLiked: false,
      isFavorited: false,
      createdAt: DateTime.now(),
    );
    _posts.insert(0, post);
    return post;
  }

  @override
  Future<ForumComment> createComment({
    required String postId,
    required String body,
  }) async {
    final id = 'mock-comment-${++_commentIdCounter}';
    final comment = ForumComment(
      id: id,
      postId: postId,
      authorId: 'current-user',
      authorName: 'You',
      body: body,
      createdAt: DateTime.now(),
    );
    _comments.putIfAbsent(postId, () => []).add(comment);
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx >= 0) {
      _posts[idx] = _posts[idx].copyWith(
        commentCount: _posts[idx].commentCount + 1,
      );
    }
    return comment;
  }

  @override
  Future<List<ForumComment>> listComments(String postId) async {
    return List.unmodifiable(_comments[postId] ?? const []);
  }

  @override
  Future<bool> toggleLike(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return false;
    if (_likedPostIds.contains(postId)) {
      _likedPostIds.remove(postId);
      _posts[idx] = _posts[idx].copyWith(
        likeCount: (_posts[idx].likeCount - 1).clamp(0, 999999),
        isLiked: false,
      );
      return false;
    } else {
      _likedPostIds.add(postId);
      _posts[idx] = _posts[idx].copyWith(
        likeCount: _posts[idx].likeCount + 1,
        isLiked: true,
      );
      return true;
    }
  }

  @override
  Future<bool> toggleFavorite(String postId) async {
    if (_favoritedPostIds.contains(postId)) {
      _favoritedPostIds.remove(postId);
      return false;
    } else {
      _favoritedPostIds.add(postId);
      return true;
    }
  }

  @override
  Future<void> reportPost(String postId, String reason, {String? detail}) async {
    // No-op in mock — report acknowledged silently.
  }
}

List<ForumPost> _buildSeedPosts() => [
  ForumPost(
    id: 'mock-post-1',
    authorId: 'demo-user',
    authorName: 'Demo User',
    title: 'How to use Present Perfect tense?',
    body:
        'I always mix up "have done" and "did". What is the rule? Any tips for remembering when to use each?',
    tag: 'Grammar',
    status: 'approved',
    likeCount: 12,
    commentCount: 4,
    isLiked: false,
    isFavorited: false,
    createdAt: DateTime.utc(2026, 6, 18, 10, 0, 0),
  ),
  ForumPost(
    id: 'mock-post-2',
    authorId: 'demo-user-2',
    authorName: 'LinguaLearner',
    title: 'Best vocabulary strategy for HSK 4?',
    body:
        'I am preparing for HSK 4 and struggling with the new vocabulary. I find spaced repetition helps but I want more tips. How did others pass this level?',
    tag: 'Vocabulary',
    status: 'approved',
    likeCount: 8,
    commentCount: 6,
    isLiked: false,
    isFavorited: false,
    createdAt: DateTime.utc(2026, 6, 17, 14, 30, 0),
  ),
  ForumPost(
    id: 'mock-post-3',
    authorId: 'demo-user-3',
    authorName: 'CultureExplorer',
    title: 'Chinese New Year greetings — what do they really mean?',
    body:
        '新年快乐 is common but I have heard 恭喜发财 and 万事如意 too. What is the cultural significance of each greeting? When do you use them?',
    tag: 'Culture',
    status: 'approved',
    likeCount: 15,
    commentCount: 9,
    isLiked: false,
    isFavorited: false,
    createdAt: DateTime.utc(2026, 6, 15, 9, 0, 0),
  ),
];

class MockAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<LearningAnalytics> getAnalytics(String uid) async {
    return LearningAnalytics.mock();
  }

  @override
  Future<List<Achievement>> getAchievements(String uid) async {
    // Use mock analytics data to evaluate achievements
    final analytics = LearningAnalytics.mock();
    return AchievementEvaluator.evaluate(
      streakDays: analytics.streakDays,
      masteredWords: analytics.masteredWords,
      totalStudyDays: analytics.totalStudyDays,
      trainingXp: analytics.trainingXp,
      hasPerfectQuiz: true,
      hasListening: true,
      hasMapLanguage: false,
    );
  }

  @override
  Future<List<Recommendation>> getRecommendations(String uid) async {
    return const [
      Recommendation(
        targetWordIds: ['mock_w1', 'mock_w2'],
        exerciseType: 'listeningWordChoice',
        reason: 'Strengthen your listening recognition with these words',
        priority: 1,
        estimatedMinutes: 2,
      ),
      Recommendation(
        targetWordIds: ['mock_w3', 'mock_w4'],
        exerciseType: 'sentenceCloze',
        reason: 'Practice using these words in context',
        priority: 2,
        estimatedMinutes: 2,
      ),
      Recommendation(
        targetWordIds: ['mock_w5'],
        exerciseType: 'meaningChoice',
        reason: 'Review the meanings of these recently learned words',
        priority: 3,
        estimatedMinutes: 1,
      ),
    ];
  }

  @override
  Future<LeaderboardResult> getLeaderboard({
    required String dimension,
    required String uid,
  }) async {
    final List<LeaderboardEntry> entries;
    switch (dimension) {
      case 'friends':
        entries = const [
          LeaderboardEntry(rank: 1, userId: 'mock_f1', name: 'Alex', xp: 450, isCurrentUser: false),
          LeaderboardEntry(rank: 2, userId: 'mock_f2', name: 'Jordan', xp: 350, isCurrentUser: false),
          LeaderboardEntry(rank: 3, userId: 'mock_me', name: 'You', xp: 300, isCurrentUser: true),
          LeaderboardEntry(rank: 4, userId: 'mock_f3', name: 'Morgan', xp: 220, isCurrentUser: false),
        ];
      case 'class':
        entries = const [
          LeaderboardEntry(rank: 1, userId: 'mock_c1', name: 'Sam', xp: 500, isCurrentUser: false),
          LeaderboardEntry(rank: 2, userId: 'mock_me', name: 'You', xp: 300, isCurrentUser: true),
          LeaderboardEntry(rank: 3, userId: 'mock_c2', name: 'Taylor', xp: 180, isCurrentUser: false),
        ];
      default: // global
        entries = const [
          LeaderboardEntry(rank: 1, userId: 'mock_g1', name: 'Alice', xp: 800, isCurrentUser: false),
          LeaderboardEntry(rank: 2, userId: 'mock_g2', name: 'Bob', xp: 600, isCurrentUser: false),
          LeaderboardEntry(rank: 3, userId: 'mock_g3', name: 'Charlie', xp: 400, isCurrentUser: false),
          LeaderboardEntry(rank: 4, userId: 'mock_g4', name: 'Diana', xp: 320, isCurrentUser: false),
          LeaderboardEntry(rank: 5, userId: 'mock_me', name: 'You', xp: 300, isCurrentUser: true),
        ];
    }
    final currentUserRank = entries
        .firstWhere(
          (e) => e.isCurrentUser,
          orElse: () => const LeaderboardEntry(rank: -1, userId: '', name: '', xp: 0, isCurrentUser: true),
        )
        .rank;
    return LeaderboardResult(
      dimension: dimension,
      entries: entries,
      currentUserRank: currentUserRank,
    );
  }
}

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository({this.currentUserId});

  final String? currentUserId;

  @override
  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    // Simulate a short network delay in demo mode.
    await Future<void>.delayed(const Duration(milliseconds: 150));

    final isOwner = currentUserId != null && currentUserId == userId;
    return {
      'uid': userId,
      'name': isOwner ? 'You' : 'Demo User',
      'isOwner': isOwner,
      'streak': 5,
      'stats': {
        'learnedWords': 89,
        'masteredWords': 34,
        'totalDays': 12,
      },
      'achievements': [
        {
          'id': 'first_lesson',
          'title': 'First Step',
          'iconKey': 'school',
          'unlocked': true,
        },
        {
          'id': 'streak_3',
          'title': '3-Day Streak',
          'iconKey': 'local_fire_department',
          'unlocked': true,
        },
      ],
      'posts': <Map<String, dynamic>>[],
      'wordbookProgress': 18,
    };
  }
}

class MockStudySpotRepository implements StudySpotRepository {
  static const _key = 'mock_study_spots';

  Future<List<StudySpot>> _read(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => StudySpot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _write(SharedPreferences prefs, List<StudySpot> spots) async {
    await prefs.setString(
        _key, jsonEncode(spots.map((s) => s.toJson()).toList()));
  }

  @override
  Future<List<StudySpot>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final spots = await _read(prefs);
    spots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return spots;
  }

  @override
  Future<StudySpot> add(StudySpot spot) async {
    final prefs = await SharedPreferences.getInstance();
    final spots = await _read(prefs);
    final id = spot.id.isNotEmpty
        ? spot.id
        : 'spot-${DateTime.now().microsecondsSinceEpoch}';
    final saved = StudySpot(
      id: id,
      name: spot.name,
      latitude: spot.latitude,
      longitude: spot.longitude,
      studyMinutes: spot.studyMinutes,
      createdAt: spot.createdAt,
    );
    spots.add(saved);
    await _write(prefs, spots);
    return saved;
  }

  @override
  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final spots = await _read(prefs);
    spots.removeWhere((s) => s.id == id);
    await _write(prefs, spots);
  }
}
