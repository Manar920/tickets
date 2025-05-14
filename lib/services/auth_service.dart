import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Add this getter to access the current user
  User? get currentUser => _auth.currentUser;

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

  // Get current user as UserModel
  Future<UserModel?> getCurrentUser() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    try {
      // Get additional user data from Firestore
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        // Use the data from Firestore to create the UserModel
        return UserModel.fromMap(doc.data()!, firebaseUser.uid);
      } else {
        // Firestore doc doesn't exist yet, create basic model
        return UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          role: 'client', // Default role
          photoURL: firebaseUser.photoURL,
        );
      }
    } catch (e) {
      print('Error getting user data: $e');
      // Return a basic model on error
      return UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        role: 'client',
        photoURL: firebaseUser.photoURL,
      );
    }
  }

  // Simplified sign-in method to focus on authentication success
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Clear any previous auth errors first
      try {
        // Use the standard sign-in method
        final UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email.trim(), 
          password: password
        );
        
        // If we get a user back, auth was successful
        return result.user != null;
      } catch (e) {
        // Catch the specific PigeonUserDetails error but consider auth successful
        // if there's a current user
        if (e.toString().contains('PigeonUserDetails')) {
          print('Ignoring known PigeonUserDetails error');
          
          // Give Firebase a moment to update the auth state
          await Future.delayed(const Duration(milliseconds: 300));
          
          // Simply check if there's a current user
          return _auth.currentUser != null;
        }
        // For other errors, re-throw so they're properly handled
        rethrow;
      }
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword(
      String email, String password, {String name = ''}) async {
    try {
      // Create the user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Update display name if provided
        if (name.isNotEmpty) {
          await userCredential.user!.updateDisplayName(name);
        }
        
        // Create user document in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name.isNotEmpty ? name : email.split('@')[0],
          'role': 'client', // Default role
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      rethrow; // Rethrow so the provider can handle specific Firebase errors
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
