class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    required this.tags,
    required this.likeCount,
    required this.commentCount,
    required this.status,
    required this.createdAt,
    this.authorAvatarUrl,
    this.imageUrls = const [],
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String title;
  final String content;
  final List<String> imageUrls;
  final List<String> tags;
  final int likeCount;
  final int commentCount;
  final String status;
  final DateTime createdAt;

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '学习者',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrls: _strings(json['imageUrls']),
      tags: _strings(json['tags']),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'published',
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class ForumComment {
  const ForumComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.status,
    required this.createdAt,
    this.authorAvatarUrl,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final String status;
  final DateTime createdAt;

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    return ForumComment(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '学习者',
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      status: json['status'] as String? ?? 'published',
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class ForumPostDetail {
  const ForumPostDetail({required this.post, required this.comments});

  final ForumPost post;
  final List<ForumComment> comments;

  factory ForumPostDetail.fromJson(Map<String, dynamic> json) {
    return ForumPostDetail(
      post: ForumPost.fromJson(json['post'] as Map<String, dynamic>),
      comments: (json['comments'] as List<dynamic>? ?? const [])
          .map((item) => ForumComment.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

List<String> _strings(Object? value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  if (value is String && value.isNotEmpty) return [value];
  return const [];
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
