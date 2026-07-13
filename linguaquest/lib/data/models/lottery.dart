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

  String get categoryLabel => categoryLabelFor(category);

  static String categoryLabelFor(String category) {
    switch (category) {
      case 'avatarFrame':
        return 'Avatar frame';
      case 'profileBackground':
        return 'Profile background';
      case 'badge':
        return 'Learning badge';
      case 'title':
        return 'Training title';
      case 'cardSkin':
        return 'Card skin';
      case 'fragment':
        return 'Comfort fragment';
      default:
        return 'Decorative asset';
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case 'rare':
        return 'Rare';
      case 'uncommon':
        return 'Uncommon';
      case 'common':
        return 'Common';
      case 'comfort':
        return 'Comfort';
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
      fragmentValue: _int(json['fragmentValue'] ?? json['fragment_value']),
      isActive: _bool(json['isActive'] ?? json['is_active']) ?? true,
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

  String get categoryLabel => LotteryPrize.categoryLabelFor(category);

  factory UserAsset.fromJson(Map<String, dynamic> json) {
    final now = DateTime.timestamp();
    return UserAsset(
      id: json['id'] as String,
      uid: json['uid'] as String,
      prizeId: json['prizeId'] as String? ?? json['prize_id'] as String? ?? '',
      category: json['category'] as String? ?? 'fragment',
      rarity: json['rarity'] as String? ?? 'comfort',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      quantity: _int(json['quantity'] ?? 1),
      fragmentValue: _int(json['fragmentValue'] ?? json['fragment_value']),
      acquiredAt: _date(json['acquiredAt'] ?? json['acquired_at']) ?? now,
      updatedAt: _date(json['updatedAt'] ?? json['updated_at']) ?? now,
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
    final balanceAfterJson = json['balanceAfter'] ?? json['balance_after'];
    return LotteryDrawResult(
      drawId: draw['id'] as String? ?? '',
      prize: LotteryPrize.fromJson(
        Map<String, dynamic>.from(json['prize'] as Map? ?? const {}),
      ),
      asset: UserAsset.fromJson(
        Map<String, dynamic>.from(json['asset'] as Map? ?? const {}),
      ),
      cost: _int(draw['cost']),
      balanceAfter: balanceAfterJson == null
          ? _int(draw['balanceAfter'] ?? draw['balance_after'])
          : _int(balanceAfterJson),
      createdAt:
          _date(draw['createdAt'] ?? draw['created_at']) ??
          DateTime.timestamp(),
    );
  }
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool? _bool(Object? value) {
  if (value is bool) return value;
  if (value is String) return bool.tryParse(value);
  return null;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
