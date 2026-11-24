/// One conversation per pair of managers: the two uids sorted and joined
/// with "_", so both phones compute the same id.
/// chatIdFor(a, b) == chatIdFor(b, a)
String chatIdFor(String a, String b) {
  final ids = [a, b]..sort();
  return ids.join('_');
}
