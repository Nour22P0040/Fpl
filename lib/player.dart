class Player {
  final String id;
  final String webName;
  final String fullName;
  final String team;
  final String position;
  final String price;
  final String code;
  final String photo;

  const Player({
    required this.id,
    required this.webName,
    required this.fullName,
    required this.team,
    required this.position,
    required this.price,
    required this.code,
    required this.photo,
  });

  /// Builds a Player from one entry of players.json.
  factory Player.fromJson(Map json) {
    final webName = (json['web_name'] ?? 'Unknown').toString();
    final fullName =
    '${json['first_name'] ?? ''} ${json['second_name'] ?? ''}'.trim();
    final price = json['price']?.toString() ??
        (json['now_cost'] != null
            ? (json['now_cost'] / 10).toStringAsFixed(1)
            : '0.0');

    return Player(
      id: json['id']?.toString() ?? webName,
      webName: webName,
      fullName: fullName.isNotEmpty
          ? fullName
          : (json['full_name'] ?? webName).toString(),
      team: json['team']?.toString() ?? 'Unknown Team',
      position:
      (json['pos'] ?? json['element_type']?.toString() ?? '').toString(),
      price: price,
      code: json['code']?.toString() ?? '',
      photo: (json['photo_url'] ?? json['image'] ?? json['photo'] ?? '')
          .toString(),
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'webName': webName,
    'fullName': fullName,
    'team': team,
    'position': position,
    'price': price,
    'code': code,
    'photo': photo,
  };

  factory Player.fromMap(Map<String, Object?> m) => Player(
    id: m['id'] as String,
    webName: m['webName'] as String,
    fullName: m['fullName'] as String,
    team: m['team'] as String,
    position: m['position'] as String,
    price: m['price'] as String,
    code: m['code'] as String,
    photo: m['photo'] as String,
  );
}