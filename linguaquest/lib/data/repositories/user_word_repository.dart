import '../models/user_word.dart';

abstract class UserWordRepository {
  Future<List<UserWord>> list(String uid);

  Future<UserWord> upsert(UserWord word);

  Future<List<UserWord>> upsertAll(List<UserWord> words);
}
