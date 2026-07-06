class ForumPost {
  const ForumPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    required this.tag,
    required this.status,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.isFavorited,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String body;
  final String tag;
  final String status; // 'pending' | 'approved' | 'rejected' | 'hidden'
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isFavorited;
  final DateTime createdAt;

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Anonymous',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      tag: json['tag'] as String? ?? 'General',
      status: json['status'] as String? ?? 'approved',
      likeCount: json['likeCount'] as int? ?? 0,
      commentCount: json['commentCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isFavorited: json['isFavorited'] as bool? ?? false,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'title': title,
    'body': body,
    'tag': tag,
    'status': status,
    'likeCount': likeCount,
    'commentCount': commentCount,
    'isLiked': isLiked,
    'isFavorited': isFavorited,
    'createdAt': createdAt.toIso8601String(),
  };

  ForumPost copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? title,
    String? body,
    String? tag,
    String? status,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isFavorited,
    DateTime? createdAt,
  }) => ForumPost(
    id: id ?? this.id,
    authorId: authorId ?? this.authorId,
    authorName: authorName ?? this.authorName,
    title: title ?? this.title,
    body: body ?? this.body,
    tag: tag ?? this.tag,
    status: status ?? this.status,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    isLiked: isLiked ?? this.isLiked,
    isFavorited: isFavorited ?? this.isFavorited,
    createdAt: createdAt ?? this.createdAt,
  );
}

class ForumComment {
  const ForumComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    return ForumComment(
      id: json['id'] as String? ?? '',
      postId: json['postId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Anonymous',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'authorId': authorId,
    'authorName': authorName,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
  };
}
