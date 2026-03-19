class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phoneNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      phoneNumber: json['phoneNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
    };
  }
}
