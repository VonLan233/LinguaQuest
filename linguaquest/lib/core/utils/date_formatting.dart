import 'package:intl/intl.dart';

final DateFormat shortDateFormat = DateFormat('MMM d');
final DateFormat fullDateFormat = DateFormat('MMM d, HH:mm');

String formatShortDate(DateTime date) => shortDateFormat.format(date);

String formatRelativeDue(DateTime date, DateTime now) {
  if (!date.isAfter(now)) {
    return 'Due now';
  }
  final difference = date.difference(now);
  if (difference.inDays >= 1) {
    return '${difference.inDays}d later';
  }
  if (difference.inHours >= 1) {
    return '${difference.inHours}h later';
  }
  return '${difference.inMinutes.clamp(1, 59)}m later';
}
