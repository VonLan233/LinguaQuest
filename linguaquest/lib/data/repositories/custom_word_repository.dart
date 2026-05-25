import '../models/custom_word.dart';

abstract class CustomWordRepository {
  Future<List<CustomWord>> list(String uid);

  Future<CustomWord> create(CustomWord word);

  Future<CustomWord> update(CustomWord word);

  Future<void> delete(String uid, String id);
}
