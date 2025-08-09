// user_model.dart (FULL CODE - FINAL)

class User {
  final int userId;
  final String name;
  final String username;
  final String email;
  final String authToken;
  final String profileImageUrl;

  User({
    required this.userId,
    required this.name,
    required this.username,
    required this.email,
    required this.authToken,
    required this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] as int,
      name: json['nama'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      authToken: json['auth_token'] as String,

      // ===================================================================
      // === KUNCI UTAMA PENCEGAHAN CRASH ===
      // ===================================================================
      // Jika 'profile_image_url' dari API null, properti ini akan
      // diisi dengan string kosong ('') untuk mencegah error.
      profileImageUrl: json['profile_image_url'] as String? ?? '',
    );
  }
}
