import '../models/forum.dart';

abstract class ForumRepository {
  Future<List<ForumPost>> listPosts();
  Future<ForumPost> getPost(String id);
  Future<ForumPost> createPost({
    required String title,
    required String body,
    required String tag,
  });
  Future<ForumComment> createComment({
    required String postId,
    required String body,
  });
  Future<List<ForumComment>> listComments(String postId);
  Future<bool> toggleLike(String postId);
  Future<bool> toggleFavorite(String postId);
  Future<void> reportPost(String postId, String reason, {String? detail});
}
