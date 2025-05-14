import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get user role from Firestore
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] ?? 'client';
      }
      
      // Default to client role if user document doesn't exist
      return 'client';
    } catch (e) {
      print('Error getting user role: $e');
      // Default to client if there's an error
      return 'client';
    }
  }
  
  // Check if user is an admin
  Future<bool> isUserAdmin(String uid) async {
    String role = await getUserRole(uid);
    return role == 'admin';
  }
  
  // Check if user is a client
  Future<bool> isUserClient(String uid) async {
    String role = await getUserRole(uid);
    return role == 'client';
  }
}
