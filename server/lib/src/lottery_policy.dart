import 'dart:math';

const lotteryDrawCost = 30;

const lotteryPrizeSeed = [
  {
    'id': 'avatar-frame-starry',
    'name': 'Star Trail Avatar Frame',
    'category': 'avatarFrame',
    'rarity': 'rare',
    'description': 'A star-trail decoration around your avatar. Cosmetic only — no learning-score boost.',
    'probability': 4,
    'fragmentValue': 18,
  },
  {
    'id': 'avatar-frame-ember',
    'name': 'Ember Flame Avatar Frame',
    'category': 'avatarFrame',
    'rarity': 'rare',
    'description': 'A burning-ember style avatar frame. Decorative only — does not affect learning fairness.',
    'probability': 3,
    'fragmentValue': 18,
  },
  {
    'id': 'profile-bg-aurora',
    'name': 'Aurora Home Background',
    'category': 'profileBackground',
    'rarity': 'rare',
    'description': 'An aurora backdrop for your profile space. Decorative only — does not affect learning fairness.',
    'probability': 4,
    'fragmentValue': 16,
  },
  {
    'id': 'profile-bg-dawn-harbor',
    'name': 'Dawn Harbor Background',
    'category': 'profileBackground',
    'rarity': 'rare',
    'description': 'A dawn harbor scene background. Display decoration only.',
    'probability': 3,
    'fragmentValue': 16,
  },
  {
    'id': 'badge-focus-sprinter',
    'name': 'Focus Sprint Badge',
    'category': 'badge',
    'rarity': 'uncommon',
    'description': 'A badge shown on your study page. Honorary decoration only.',
    'probability': 9,
    'fragmentValue': 8,
  },
  {
    'id': 'badge-night-owl',
    'name': 'Night Owl Badge',
    'category': 'badge',
    'rarity': 'uncommon',
    'description': 'A badge for late-night learners. Does not raise quiz scores.',
    'probability': 7,
    'fragmentValue': 8,
  },
  {
    'id': 'badge-anniversary-lantern',
    'name': 'Anniversary Lantern Badge',
    'category': 'badge',
    'rarity': 'rare',
    'description': 'A limited event badge. Honorary keepsake only.',
    'probability': 2,
    'fragmentValue': 20,
  },
  {
    'id': 'title-arena-scout',
    'name': 'Training Ground Scout Title',
    'category': 'title',
    'rarity': 'uncommon',
    'description': 'A training-ground title. Does not raise quiz scores.',
    'probability': 8,
    'fragmentValue': 8,
  },
  {
    'id': 'title-lexicon-keeper',
    'name': 'Vocabulary Guardian Title',
    'category': 'title',
    'rarity': 'uncommon',
    'description': 'A title for dedicated vocabulary learners. Does not affect learning fairness.',
    'probability': 7,
    'fragmentValue': 8,
  },
  {
    'id': 'title-dawn-voyager',
    'name': 'Dawn Voyager Title',
    'category': 'title',
    'rarity': 'rare',
    'description': 'A rare explorer title. Decorative only.',
    'probability': 3,
    'fragmentValue': 16,
  },
  {
    'id': 'card-skin-mint',
    'name': 'Mint Card Skin',
    'category': 'cardSkin',
    'rarity': 'common',
    'description': 'A word-card visual skin. Does not change the memory algorithm.',
    'probability': 12,
    'fragmentValue': 5,
  },
  {
    'id': 'card-skin-sakura',
    'name': 'Sakura Card Skin',
    'category': 'cardSkin',
    'rarity': 'common',
    'description': 'A sakura-style card skin. Does not change the memory algorithm.',
    'probability': 11,
    'fragmentValue': 5,
  },
  {
    'id': 'card-skin-midnight',
    'name': 'Midnight Card Skin',
    'category': 'cardSkin',
    'rarity': 'common',
    'description': 'A dark midnight-style card skin. Does not affect learning results.',
    'probability': 10,
    'fragmentValue': 5,
  },
  {
    'id': 'card-skin-citrus',
    'name': 'Citrus Card Skin',
    'category': 'cardSkin',
    'rarity': 'common',
    'description': 'A fresh citrus-toned card skin. Visual decoration only.',
    'probability': 7,
    'fragmentValue': 4,
  },
  {
    'id': 'comfort-star-fragments',
    'name': 'Stardust Fragment',
    'category': 'fragment',
    'rarity': 'comfort',
    'description': 'A consolation reward you can accumulate to redeem decorative assets.',
    'probability': 10,
    'fragmentValue': 3,
  },
];

Map<String, dynamic> chooseLotteryPrize(
  List<Map<String, dynamic>> prizes, {
  Random? random,
}) {
  final active = prizes
      .where((prize) => (prize['is_active'] ?? prize['isActive']) != false)
      .toList();
  final pool = active.isEmpty ? lotteryPrizeSeed : active;
  final totalWeight = pool.fold<double>(0, (total, prize) {
    return total + _probability(prize['probability']);
  });
  final roll = (random ?? Random()).nextDouble() * totalWeight;
  var cursor = 0.0;
  for (final prize in pool) {
    cursor += _probability(prize['probability']);
    if (roll <= cursor) return prize;
  }
  return pool.last;
}

double _probability(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
