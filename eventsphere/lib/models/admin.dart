// Admin is now a User with role='admin'. This class is kept for compatibility.
import 'user.dart';

class Admin {
  final int? id;
  final String username;
  final String password;

  Admin({this.id, required this.username, required this.password});

  factory Admin.fromUser(User user) =>
      Admin(id: user.id, username: user.username, password: user.password);

  factory Admin.fromMap(Map<String, dynamic> map) => Admin(
        id: map['id'],
        username: map['username'],
        password: map['password'],
      );
}
