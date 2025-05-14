import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Convert Firebase User to our custom User model
  Future<UserModel?> _userFromFirebaseUser(User? user) async {
    if (user == null) return null;
    
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('users').doc(user.uid).get();
      
      if (docSnapshot.exists) {
        Map<String, dynamic> userData = docSnapshot.data() as Map<String, dynamic>;
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: userData['name'] ?? '', // Default to empty string instead of null
          photoURL: user.photoURL ?? userData['photoURL'],
          role: userData['role'] ?? 'client',
        );
      } else {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '', // Default to empty string
          photoURL: user.photoURL,
          role: 'client',
        );
        
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Auth state changes stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().asyncMap(_userFromFirebaseUser);
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    return await _userFromFirebaseUser(_auth.currentUser);
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return await _userFromFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      if (e.toString().contains('PigeonUserDetails')) {
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          return await _userFromFirebaseUser(currentUser);
        }
      }
      print('Error signing in: $e');
      throw Exception('Authentication failed. Please try again.');
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password, {String? name, String role = 'client'}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          name: name ?? '', // Can be null
          photoURL: user.photoURL,
          role: role,
        );
        
        // Save user to Firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        
        // Update user display name in Firebase Auth if name is provided
        if (name != null && name.isNotEmpty) {
          await user.updateDisplayName(name);
        }
        
        return newUser;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      if (e.toString().contains('PigeonUserDetails')) {
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          return await _userFromFirebaseUser(currentUser);
        }
      }
      print('Error registering: $e');
      throw Exception('Registration failed. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      throw e;
    }
  }

  // Update user's role
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      print('Error updating user role: $e');
      throw Exception('Failed to update user role: $e');
    }
  }

  // Get user information from Firestore
  Future<Map<String, dynamic>?> getUserInfo(String uid) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore.collection('users').doc(uid).get();
      
      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }
}
