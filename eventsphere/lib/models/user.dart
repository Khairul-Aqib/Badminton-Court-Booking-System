class User {
  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final String username;
  final String password;
  final String role;

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.username,
    required this.password,
    this.role = 'user',
  });

  String get name => fullName;

  Map<String, dynamic> toInsertMap() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'username': username,
        'password': password,
        'role': role,
      };

  Map<String, dynamic> toUpdateMap() => {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'username': username,
        'password': password,
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        fullName: map['full_name'] ?? '',
        email: map['email'] ?? '',
        phone: map['phone'] ?? '',
        username: map['username'] ?? '',
        password: map['password'] ?? '',
        role: map['role'] ?? 'user',
      );

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? username,
    String? password,
    String? role,
  }) =>
      User(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        username: username ?? this.username,
        password: password ?? this.password,
        role: role ?? this.role,
      );
}
