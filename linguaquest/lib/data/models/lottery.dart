class LotteryPrize {
  const LotteryPrize({
    required this.id,
    required this.name,
    required this.category,
    required this.rarity,
    required this.description,
    required this.probability,
    required this.fragmentValue,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String category;
  final String rarity;
  final String description;
  final double probability;
  final int fragmentValue;
  final bool isActive;

  bool get isComfortReward => category == 'fragment' || rarity == 'comfort';

  String get categoryLabel {
    switch (category) {
      case 'avatarFrame':
        return '头像框';
      case 'profileBackground':
        return '主页背景';
      case 'badge':
        return '学习徽章';
      case 'title':
        return '训练称号';
      case 'cardSkin':
        return '卡片皮肤';
      case 'fragment':
        return '安慰碎片';
      default:
        return '装饰资产';
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case 'rare':
        return '稀有';
      case 'uncommon':
        return '进阶';
      case 'common':
        return '普通';
      case 'comfort':
        return '安慰';
      default:
        return rarity;
    }
  }

  factory LotteryPrize.fromJson(Map<String, dynamic> json) {
    return LotteryPrize(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'fragment',
      rarity: json['rarity'] as String? ?? 'comfort',
      description: json['description'] as String? ?? '',
      probability: _double(json['probability']),
      fragmentValue: json['fragmentValue'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rarity': rarity,
      'description': description,
      'probability': probability,
      'fragmentValue': fragmentValue,
      'isActive': isActive,
    };
  }
}

class UserAsset {
  const UserAsset({
    required this.id,
    required this.uid,
    required this.prizeId,
    required this.category,
    required this.rarity,
    required this.name,
    required this.description,
    required this.quantity,
    required this.fragmentValue,
    required this.acquiredAt,
    required this.updatedAt,
  });

  final String id;
  final String uid;
  final String prizeId;
  final String category;
  final String rarity;
  final String name;
  final String description;
  final int quantity;
  final int fragmentValue;
  final DateTime acquiredAt;
  final DateTime updatedAt;

  int get totalFragments => fragmentValue * quantity;

  String get categoryLabel => LotteryPrize(
    id: prizeId,
    name: name,
    category: category,
    rarity: rarity,
    description: description,
    probability: 0,
    fragmentValue: fragmentValue,
  ).categoryLabel;

  factory UserAsset.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return UserAsset(
      id: json['id'] as String,
      uid: json['uid'] as String,
      prizeId: json['prizeId'] as String? ?? json['prize_id'] as String? ?? '',
      category: json['category'] as String? ?? 'fragment',
      rarity: json['rarity'] as String? ?? 'comfort',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      fragmentValue: json['fragmentValue'] as int? ?? 0,
      acquiredAt: _date(json['acquiredAt']) ?? now,
      updatedAt: _date(json['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'prizeId': prizeId,
      'category': category,
      'rarity': rarity,
      'name': name,
      'description': description,
      'quantity': quantity,
      'fragmentValue': fragmentValue,
      'acquiredAt': acquiredAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class LotteryDrawResult {
  const LotteryDrawResult({
    required this.drawId,
    required this.prize,
    required this.asset,
    required this.cost,
    required this.balanceAfter,
    required this.createdAt,
  });

  final String drawId;
  final LotteryPrize prize;
  final UserAsset asset;
  final int cost;
  final int balanceAfter;
  final DateTime createdAt;

  factory LotteryDrawResult.fromJson(Map<String, dynamic> json) {
    final draw = Map<String, dynamic>.from(json['draw'] as Map? ?? const {});
    return LotteryDrawResult(
      drawId: draw['id'] as String? ?? '',
      prize: LotteryPrize.fromJson(
        Map<String, dynamic>.from(json['prize'] as Map? ?? const {}),
      ),
      asset: UserAsset.fromJson(
        Map<String, dynamic>.from(json['asset'] as Map? ?? const {}),
      ),
      cost: draw['cost'] as int? ?? 0,
      balanceAfter:
          json['balanceAfter'] as int? ?? draw['balanceAfter'] as int? ?? 0,
      createdAt: _date(draw['createdAt']) ?? DateTime.now(),
    );
  }
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
