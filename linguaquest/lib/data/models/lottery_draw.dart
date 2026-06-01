class LotteryDraw {
  const LotteryDraw({
    required this.id,
    required this.prize,
    required this.pointsCost,
    required this.drawnAt,
  });

  final String id;
  final String prize;
  final int pointsCost;
  final DateTime drawnAt;

  factory LotteryDraw.fromJson(Map<String, dynamic> json) {
    return LotteryDraw(
      id: json['id'] as String? ?? '',
      prize: json['prize'] as String? ?? '学习徽章',
      pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
      drawnAt: _date(json['drawnAt']) ?? DateTime.now(),
    );
  }
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
