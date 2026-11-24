/// Turns a lastSeen timestamp (milliseconds since epoch) into short text.
/// Plain Dart: no Flutter or Firebase, so it is easy to unit test.
String lastSeenText(int? millis, {DateTime? now}) {
  if (millis == null) return 'never seen';

  final current = now ?? DateTime.now();
  final seen = DateTime.fromMillisecondsSinceEpoch(millis);
  final diff = current.difference(seen);

  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}
