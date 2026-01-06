class UserProfile {
  final String id;
  final String email;
  final String userType;
  final String? name;
  final String? phone;

  UserProfile({
    required this.id,
    required this.email,
    required this.userType,
    this.name,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'],
        email: json['email'] ?? '',
        userType: json['user_type'] ?? 'adoptante',
        name: json['name'],
        phone: json['phone'],
      );
}