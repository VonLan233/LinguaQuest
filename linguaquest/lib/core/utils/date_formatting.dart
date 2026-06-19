import '../../l10n/generated/app_localizations.dart';

String formatShortDate(DateTime date) => '${date.month}月${date.day}日';

String formatFullDate(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.month}月${date.day}日 $hour:$minute';
}

String formatRelativeDue(DateTime date, DateTime now, AppLocalizations l10n) {
  if (!date.isAfter(now)) {
    return l10n.dueNow;
  }
  final difference = date.difference(now);
  if (difference.inDays >= 1) {
    return l10n.dueInDays(difference.inDays);
  }
  if (difference.inHours >= 1) {
    return l10n.dueInHours(difference.inHours);
  }
  return l10n.dueInMinutes(difference.inMinutes.clamp(1, 59));
}
