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

  
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'client',
      photoURL: data['photoURL'],
    );
  }

  
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'photoURL': photoURL,
    };
  }

  
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
