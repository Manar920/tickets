import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Initialize the provider by listening to auth changes
    _authService.user.listen((UserModel? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      // Handle specific Firebase Auth error messages
      switch (e.code) {
        case 'user-not-found':
          _error = 'No user found with this email.';
          break;
        case 'wrong-password':
          _error = 'Wrong password provided.';
          break;
        case 'invalid-email':
          _error = 'Invalid email format.';
          break;
        case 'user-disabled':
          _error = 'This user has been disabled.';
          break;
        case 'too-many-requests':
          _error = 'Too many attempts. Try again later.';
          break;
        default:
          _error = 'Authentication error: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      
      // If the error contains PigeonUserDetails, check auth state
      if (e.toString().contains('PigeonUserDetails')) {
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          _user = currentUser;
          _error = null;
          notifyListeners();
          return true;
        }
        _error = 'Authentication failed. Please try again.';
      }
      
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.registerWithEmailAndPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      // Handle specific Firebase Auth error messages
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'Email is already in use.';
          break;
        case 'weak-password':
          _error = 'Password is too weak.';
          break;
        case 'invalid-email':
          _error = 'Invalid email format.';
          break;
        case 'operation-not-allowed':
          _error = 'Email/password accounts are not enabled.';
          break;
        default:
          _error = 'Registration error: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      
      // Same workaround for registration
      if (e.toString().contains('PigeonUserDetails')) {
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          _user = currentUser;
          _error = null;
          notifyListeners();
          return true;
        }
        _error = 'Registration failed. Please try again.';
      }
      
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to sign out: $e';
      notifyListeners();
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
