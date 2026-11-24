import 'package:flutter_test/flutter_test.dart';
import 'package:fplhub_app/data/last_seen.dart';

void main() {
  final now = DateTime(2026, 11, 24, 12, 0);
  int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch;

  test('null is never seen', () {
    expect(lastSeenText(null, now: now), 'never seen');
  });

  test('under a minute is just now', () {
    expect(lastSeenText(ago(const Duration(seconds: 30)), now: now), 'just now');
  });

  test('minutes, hours, days', () {
    expect(lastSeenText(ago(const Duration(minutes: 5)), now: now), '5 min ago');
    expect(lastSeenText(ago(const Duration(hours: 3)), now: now), '3 h ago');
    expect(lastSeenText(ago(const Duration(days: 2)), now: now), '2 d ago');
  });
}
