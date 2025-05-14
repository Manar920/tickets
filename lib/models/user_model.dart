class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoURL;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoURL,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoURL: map['photoURL'],
      role: map['role'] ?? 'client', // Default role is client
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoURL': photoURL,
      'role': role,
    };
  }
}
