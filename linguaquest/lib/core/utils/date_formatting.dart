String formatShortDate(DateTime date) => '${date.month}月${date.day}日';

String formatFullDate(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.month}月${date.day}日 $hour:$minute';
}

String formatRelativeDue(DateTime date, DateTime now) {
  if (!date.isAfter(now)) {
    return '现在到期';
  }
  final difference = date.difference(now);
  if (difference.inDays >= 1) {
    return '${difference.inDays} 天后';
  }
  if (difference.inHours >= 1) {
    return '${difference.inHours} 小时后';
  }
  return '${difference.inMinutes.clamp(1, 59)} 分钟后';
}
