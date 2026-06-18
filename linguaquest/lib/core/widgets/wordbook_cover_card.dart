import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// A programmatic, styled book-cover card (no network image, no mascot).
///
/// Renders a rounded card with an exam-themed gradient, a small exam badge /
/// abbreviation (e.g. IELTS / TOEFL / GRE), and the book title. The hue varies
/// deterministically by the book's exam type / id so each series reads as a
/// distinct "cover".
///
/// Used both as the hero current-book cover and as the small cards in the
/// horizontal series scroller.
class WordbookCoverCard extends StatelessWidget {
  const WordbookCoverCard({
    required this.examType,
    required this.bookId,
    required this.title,
    this.width = 96,
    this.height = 128,
    super.key,
  });

  /// Exam type string (e.g. "IELTS"); falls back to [bookId] when empty.
  final String examType;
  final String bookId;

  /// Localized display title shown small at the bottom of the cover.
  final String title;

  final double width;
  final double height;

  /// Deterministic gradient for a given exam/book key.
  static WordbookCoverPalette paletteFor(String examType, String bookId) {
    final key = (examType.isNotEmpty ? examType : bookId).toLowerCase();
    switch (key) {
      case 'ielts':
        return const WordbookCoverPalette(Color(0xFF3A6FE0), Color(0xFF2453C4));
      case 'toefl':
        return const WordbookCoverPalette(Color(0xFF2BB6A8), Color(0xFF1C8C86));
      case 'gre':
        return const WordbookCoverPalette(Color(0xFF7A5AE0), Color(0xFF5733B8));
      case 'cet4':
      case 'cet6':
        return const WordbookCoverPalette(Color(0xFFE07A3A), Color(0xFFC4541F));
      case 'beginner':
        return const WordbookCoverPalette(Color(0xFF3FB45C), Color(0xFF2C8A43));
      case 'kaoyan':
        return const WordbookCoverPalette(Color(0xFFE05A7A), Color(0xFFB83356));
      default:
        return const WordbookCoverPalette(Color(0xFF3A6FE0), Color(0xFF2453C4));
    }
  }

  /// Short badge label: the exam type if present, else the upper-cased id.
  String get _badge {
    final raw = examType.isNotEmpty ? examType : bookId;
    return raw.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final WordbookCoverPalette palette = paletteFor(examType, bookId);
    final radius = BorderRadius.circular(AppTokens.radiusTile);
    final compact = width < 84;
    final titleParts = _splitChineseVocabularyTitle(title);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.top, palette.bottom],
        ),
      ),
      child: Stack(
        children: [
          // Decorative spine highlight on the left edge.
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(color: Colors.white.withValues(alpha: 0.18)),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? AppTokens.s8 : AppTokens.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  ),
                  child: Text(
                    _badge,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 9 : 11,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                if (titleParts == null)
                  Text(
                    title,
                    style: _titleStyle(compact),
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleParts.$1,
                        style: _titleStyle(compact),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        titleParts.$2,
                        style: _titleStyle(compact),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _titleStyle(bool compact) {
    return TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: compact ? 11 : 13,
      height: 1.2,
    );
  }

  (String, String)? _splitChineseVocabularyTitle(String value) {
    const suffix = '词汇';
    if (!value.endsWith(suffix) || value.length <= suffix.length) {
      return null;
    }
    final prefix = value.substring(0, value.length - suffix.length).trim();
    if (prefix.isEmpty) return null;
    return (prefix, suffix);
  }
}

/// Resolved top/bottom gradient stops for a [WordbookCoverCard].
class WordbookCoverPalette {
  const WordbookCoverPalette(this.top, this.bottom);
  final Color top;
  final Color bottom;
}
