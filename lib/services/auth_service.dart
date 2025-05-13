import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Convert Firebase User to our custom User model
  UserModel? _userFromFirebaseUser(User? user) {
    return user != null
        ? UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            photoURL: user.photoURL,
          )
        : null;
  }

  // Auth state changes stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  // Get current user
  UserModel? get currentUser {
    return _userFromFirebaseUser(_auth.currentUser);
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      // Use try-catch with specific error handling
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebaseUser(credential.user);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      rethrow; // Rethrow to be handled by the provider
    } catch (e) {
      // Catch the specific PigeonUserDetails error
      if (e.toString().contains('PigeonUserDetails')) {
        // Wait a moment and check if user is actually signed in
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          return _userFromFirebaseUser(currentUser);
        }
      }
      print('Error signing in: $e');
      throw Exception('Authentication failed. Please try again.');
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebaseUser(credential.user);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      // Similar handling for registration
      if (e.toString().contains('PigeonUserDetails')) {
        await Future.delayed(const Duration(milliseconds: 500));
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          return _userFromFirebaseUser(currentUser);
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
}
