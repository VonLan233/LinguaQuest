import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Only basic learning can be completed locally. Purchases, rewards, AI,
/// account changes and validation failures always require a server response.
class OfflineStudyStore extends Interceptor {
  OfflineStudyStore(this.dio);
  final Dio dio;
  String? userId;
  bool offline = false;
  bool localOnly = false;
  Future<void> _writes = Future.value();

  static const _reads = {'/me', '/user-words', '/study-plan', '/custom-words'};
  static const _events = {
    '/study-sessions',
    '/review-events',
    '/exercise-records',
  };
  bool _canWrite(RequestOptions r) =>
      (r.method == 'PATCH' && r.path == '/me') ||
      (r.method == 'PUT' && r.path == '/study-plan') ||
      (r.method == 'POST' &&
          (_events.contains(r.path) ||
              r.path == '/user-words' ||
              r.path == '/user-words/batch'));
  String _key(String uid) => 'linguaquest.offline.study.$uid';

  Future<Map<String, dynamic>> _load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null) {
      return {'cache': <String, dynamic>{}, 'pending': <dynamic>[]};
    }
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _change(String uid, void Function(Map<String, dynamic>) change) {
    final operation = _writes.then((_) async {
      final state = await _load(uid);
      change(state);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_key(uid), jsonEncode(state))) {
        throw StateError('Unable to persist offline learning');
      }
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    final uid = profile['uid'] as String;
    userId = uid;
    await _change(uid, (s) => (s['cache'] as Map)['/me'] = {'user': profile});
  }

  Future<void> flush() async {
    final uid = userId;
    if (uid == null || localOnly) return;
    await _writes;
    final state = await _load(uid);
    for (final raw in List.of(state['pending'] as List)) {
      if (userId != uid) return;
      final event = Map<String, dynamic>.from(raw as Map);
      try {
        await dio.request<dynamic>(
          event['path'] as String,
          data: event['data'],
          options: Options(
            method: event['method'] as String,
            extra: {'offlineReplay': true},
          ),
        );
        await _change(
          uid,
          (s) => (s['pending'] as List).removeWhere(
            (e) => (e as Map)['id'] == event['id'],
          ),
        );
      } on DioException catch (error) {
        if (_transportFailure(error)) {
          offline = true;
          return;
        }
        // Keep rejected writes inspectable; never silently discard progress.
        rethrow;
      }
    }
    offline = false;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra['offlineUser'] = userId;
    if (_reads.contains(options.path) || _canWrite(options)) {
      options.connectTimeout = const Duration(seconds: 4);
      options.receiveTimeout = const Duration(seconds: 4);
    }
    if (options.extra['offlineReplay'] == true ||
        options.path.startsWith('/auth/') ||
        options.path.startsWith('/ai/') ||
        (!offline && !localOnly) ||
        userId == null) {
      handler.next(options);
      return;
    }
    try {
      final response = await _local(options);
      if (response != null) {
        handler.resolve(response);
        return;
      }
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'This feature needs internet',
        ),
      );
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final request = response.requestOptions;
    final uid = request.extra['offlineUser'] as String?;
    if (uid != null && request.extra['offlineReplay'] != true) {
      try {
        if (request.method == 'GET' && _reads.contains(request.path)) {
          await _change(
            uid,
            (s) => (s['cache'] as Map)[request.path] = response.data,
          );
        } else if (_canWrite(request)) {
          await _apply(request, uid, enqueue: false);
        }
      } catch (error) {
        handler.reject(DioException(requestOptions: request, error: error));
        return;
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.requestOptions.extra['offlineReplay'] == true ||
        !_transportFailure(err)) {
      handler.next(err);
      return;
    }
    offline = true;
    try {
      final response = await _local(err.requestOptions);
      if (response != null) {
        handler.resolve(response);
        return;
      }
    } catch (storageError) {
      handler.reject(
        DioException(requestOptions: err.requestOptions, error: storageError),
      );
      return;
    }
    handler.next(err);
  }

  Future<Response<dynamic>?> _local(RequestOptions request) async {
    final uid = request.extra['offlineUser'] as String?;
    if (uid == null || uid != userId) return null;
    dynamic data;
    if (_canWrite(request)) {
      data = await _apply(request, uid, enqueue: !localOnly);
    } else if (request.method == 'GET' && _reads.contains(request.path)) {
      await _writes;
      final cache = (await _load(uid))['cache'] as Map;
      data = cache[request.path];
      if (data == null) {
        if (request.path == '/user-words' || request.path == '/custom-words') {
          data = <dynamic>[];
        } else if (request.path == '/study-plan') {
          data = {'studyPlan': null};
        } else {
          return null;
        }
      }
    } else {
      return null;
    }
    return Response<dynamic>(
      requestOptions: request,
      statusCode: 200,
      data: data,
      extra: {'savedLocally': true},
    );
  }

  Future<dynamic> _apply(
    RequestOptions request,
    String uid, {
    required bool enqueue,
  }) async {
    dynamic result;
    await _change(uid, (s) {
      final cache = s['cache'] as Map;
      final body = Map<String, dynamic>.from(request.data as Map);
      if (request.path == '/me') {
        final previous = Map<String, dynamic>.from(
          (cache['/me'] as Map)['user'] as Map,
        );
        result = {
          'user': {...previous, ...body},
        };
        cache['/me'] = result;
      } else if (request.path == '/study-plan') {
        result = {'studyPlan': body};
        cache['/study-plan'] = result;
      } else if (request.path.startsWith('/user-words')) {
        final incoming = request.path.endsWith('/batch')
            ? body['words'] as List
            : [body];
        final words = <String, dynamic>{
          for (final w in (cache['/user-words'] as List? ?? []))
            (w as Map)['id'] as String: w,
          for (final w in incoming) (w as Map)['id'] as String: w,
        };
        cache['/user-words'] = words.values.toList();
        result = request.path.endsWith('/batch')
            ? {'words': incoming}
            : {'word': body};
      } else {
        result = {'recorded': true};
      }
      if (enqueue) {
        (s['pending'] as List).add({
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'method': request.method,
          'path': request.path,
          'data': body,
        });
      }
    });
    return result;
  }

  static bool _transportFailure(DioException e) =>
      e.response == null &&
      {
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      }.contains(e.type);
}
