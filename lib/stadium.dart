class Stadium {
  final String name;
  final double lat;
  final double lng;

  const Stadium(this.name, this.lat, this.lng);
}

// PLACEHOLDER coordinates (approximate). Replace with exact values
// from Google Maps (long-press the pitch -> copy lat, lng).
const List<Stadium> stadiums = [
  Stadium('Cairo International Stadium', 30.0691, 31.3121),
  Stadium('30 June Stadium', 30.0657, 31.4600),
  Stadium('Petro Sport Stadium', 30.0605, 31.4445),
  Stadium('Al Salam Stadium', 30.1325, 31.3949),
  Stadium('Mokhtar El-Tetsh Stadium', 30.0425, 31.2236),
];
