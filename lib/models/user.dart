class User {
  final int id;
  final String name;
  final String? username;
  final String email;
  final List<String> roles;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    this.username,
    required this.email,
    required this.roles,
    this.isActive = true,
  });

  bool get isOwner => roles.contains('owner') || roles.contains('super_admin');

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String?,
      email: json['email'] as String,
      roles: List<String>.from(json['roles'] ?? []),
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'roles': roles,
      'is_active': isActive,
    };
  }
}
