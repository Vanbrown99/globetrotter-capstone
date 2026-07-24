class AppUser {
  final String username;
  final String email;
  final String token;

  AppUser({
    required this.username,
    required this.email,
    required this.token,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      username: json['username'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
    );
  }
}
