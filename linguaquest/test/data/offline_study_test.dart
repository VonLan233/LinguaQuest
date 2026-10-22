import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/data/remote/api_client.dart';
import 'package:linguaquest/data/offline_wordbook_store.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_word.dart';
import 'package:linguaquest/data/repositories/api_repositories.dart';

class _Network implements HttpClientAdapter {
  bool connected = false;
  int status = 200;
  Object body = {'recorded': true};
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions request,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(request);
    if (!connected) {
      throw DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _profile(String uid) => {
  'uid': uid,
  'name': 'Learner',
  'email': '$uid@example.com',
  'streak': 0,
};
ApiClient _client(_Network network) {
  final client = ApiClient();
  client.dio.options.baseUrl = 'https://example.test';
  client.dio.httpClientAdapter = network;
  client.setToken('test-session');
  return client;
}

WordBook _book() => WordBook.fromJson(
  jsonDecode(
        File('lib/assets/data/wordbook_ja_starter.json').readAsStringSync(),
      )
      as Map<String, dynamic>,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'offline user words, plan and profile survive restart and replay with stable IDs',
    () async {
      final firstNetwork = _Network();
      final first = _client(firstNetwork);
      await first.offlineStore.cacheProfile(_profile('alice'));
      await first.dio.get<Map<String, dynamic>>(
        '/me',
      ); // detects transport failure
      final word = UserWord.create(
        uid: 'alice',
        word: _book().words.first,
        wordBookId: 'ja_starter',
      );
      await ApiUserWordRepository(first).upsert(word);
      await first.dio.put<Map<String, dynamic>>(
        '/study-plan',
        data: {'id': 'plan-a', 'wordBookId': 'ja_starter'},
      );
      await first.dio.patch<Map<String, dynamic>>('/me', data: {'streak': 1});
      await first.dio.post<void>('/review-events', data: {'id': 'review-once'});
      await first.dio.post<void>(
        '/study-sessions',
        data: {'id': 'session-once'},
      );

      final secondNetwork = _Network();
      final second = _client(secondNetwork);
      second.offlineStore.userId = 'alice';
      expect(
        (await second.dio.get<Map<String, dynamic>>(
          '/me',
        )).data!['user']['streak'],
        1,
      );
      expect(
        (await ApiUserWordRepository(second).list('alice')).single.wordId,
        word.wordId,
      );
      expect(
        (await second.dio.get<Map<String, dynamic>>(
          '/study-plan',
        )).data!['studyPlan']['wordBookId'],
        'ja_starter',
      );
      secondNetwork.connected = true;
      await second.offlineStore.flush();
      final replayed = secondNetwork.requests
          .where((r) => r.method != 'GET')
          .toList();
      expect(replayed.length, 5);
      expect(replayed.last.data['id'], 'session-once');
      final count = secondNetwork.requests.length;
      await second.offlineStore.flush();
      expect(
        secondNetwork.requests.length,
        count,
        reason: 'Successful replay is removed durably',
      );
    },
  );

  test('account switch cannot read or replay another account’s data', () async {
    final network = _Network();
    final client = _client(network);
    await client.offlineStore.cacheProfile(_profile('alice'));
    await client.dio.get<dynamic>('/me');
    await client.dio.post<void>('/review-events', data: {'id': 'alice-review'});
    await client.offlineStore.cacheProfile(_profile('bob'));
    expect(
      (await client.dio.get<Map<String, dynamic>>('/me')).data!['user']['uid'],
      'bob',
    );
    expect(await ApiUserWordRepository(client).list('bob'), isEmpty);
    network.connected = true;
    final before = network.requests.length;
    await client.offlineStore.flush();
    expect(network.requests.length, before);
  });

  test('HTTP rejection is not reported as a local save', () async {
    final network = _Network()
      ..connected = true
      ..status = 401;
    final client = _client(network);
    await client.offlineStore.cacheProfile(_profile('alice'));
    await expectLater(
      client.dio.patch<dynamic>('/me', data: {'streak': 99}),
      throwsA(isA<DioException>()),
    );
    network.connected = false;
    expect(
      (await client.dio.get<Map<String, dynamic>>(
        '/me',
      )).data!['user']['streak'],
      0,
    );
    network.connected = true;
    network.status = 200;
    final before = network.requests.length;
    await client.offlineStore.flush();
    expect(network.requests.length, before);
  });

  test(
    'download remains available after restart; invalid update keeps previous book',
    () async {
      final network = _Network()
        ..connected = true
        ..body = {'wordbook': _book().toJson()};
      final client = _client(network);
      await ApiLearningRepository(client).downloadWordBook('ja_starter');
      expect((await OfflineWordbookStore().load()).single.words.length, 24);
      network.body = {
        'wordbook': {..._book().toJson(), 'id': 'wrong-book'},
      };
      await expectLater(
        ApiLearningRepository(client).downloadWordBook('ja_starter'),
        throwsA(isA<FormatException>()),
      );
      expect((await OfflineWordbookStore().load()).single.id, 'ja_starter');
      final secondRepo = ApiLearningRepository(_client(_Network()));
      expect(await secondRepo.downloadedWordBookIds(), {'ja_starter'});
      await secondRepo.clearOfflineCache();
      expect(await secondRepo.downloadedWordBookIds(), {'ja_starter'});
      await secondRepo.removeDownloadedWordBook('ja_starter');
      expect(await secondRepo.downloadedWordBookIds(), isEmpty);
    },
  );
}
