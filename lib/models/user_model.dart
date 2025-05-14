class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? photoURL;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.photoURL,
  });

  // Create a UserModel from a Firebase user and additional data
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'client',
      photoURL: data['photoURL'],
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'photoURL': photoURL,
    };
  }

  // Create a copy with some fields replaced
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? photoURL,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      photoURL: photoURL ?? this.photoURL,
    );
  }
}
