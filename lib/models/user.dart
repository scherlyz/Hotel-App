class User {
  final int id;
  final String username;
  final String role;

  User({
    required this.id,
    required this.username,
    this.role = 'user',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
    );
  }

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role,
      };
}