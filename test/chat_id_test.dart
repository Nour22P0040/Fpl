import 'package:flutter_test/flutter_test.dart';
import 'package:fplhub_app/data/chat_id.dart';

void main() {
  test('same id in both directions', () {
    expect(chatIdFor('alice', 'bob'), chatIdFor('bob', 'alice'));
  });

  test('sorted and joined with an underscore', () {
    expect(chatIdFor('zed', 'amy'), 'amy_zed');
  });
}
