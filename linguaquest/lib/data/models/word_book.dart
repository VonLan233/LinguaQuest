class WordBook {
  const WordBook({
    required this.id,
    required this.title,
    required this.category,
    required this.examType,
    required this.coverUrl,
    required this.totalWords,
    required this.description,
    required this.wordIds,
  });

  final String id;
  final String title;
  final String category;
  final String examType;
  final String coverUrl;
  final int totalWords;
  final String description;
  final List<String> wordIds;

  factory WordBook.fromJson(Map<String, dynamic> json) {
    return WordBook(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      examType: json['examType'] as String,
      coverUrl: json['coverUrl'] as String? ?? '',
      totalWords: json['totalWords'] as int? ?? 0,
      description: json['description'] as String,
      wordIds: (json['wordIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'examType': examType,
        'coverUrl': coverUrl,
        'totalWords': totalWords,
        'description': description,
        'wordIds': wordIds,
      };
}
