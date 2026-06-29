class StudySpot {
  const StudySpot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.studyMinutes,
    required this.createdAt,
    this.visitCount = 1,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int studyMinutes;
  final DateTime createdAt;
  final int visitCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'studyMinutes': studyMinutes,
        'visitCount': visitCount,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory StudySpot.fromJson(Map<String, dynamic> json) => StudySpot(
        id: json['id'].toString(),
        name: (json['name'] as String?) ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        studyMinutes: (json['studyMinutes'] as num?)?.toInt() ?? 0,
        visitCount: (json['visitCount'] as num?)?.toInt() ?? 1,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}
