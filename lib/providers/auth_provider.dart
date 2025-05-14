import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final RoleService _roleService = RoleService();
  UserModel? _user;
  String? _role;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _role == 'admin';
  bool get isClient => _role == 'client';

  AuthProvider() {
    // Initialize the provider by listening to auth changes
    _authService.user.listen((UserModel? user) async {
      _user = user;
      if (user != null) {
        _role = await _roleService.getUserRole(user.uid);
      } else {
        _role = null;
      }
      notifyListeners();
    });
    
    // Initialize current user on startup
    _initCurrentUser();
  }
  
  // Improved sign in with better error handling and prevention of auto-logout
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // Store current auth state to detect changes
    final wasAuthenticated = _user != null;

    try {
      // Only log success/failure without the full error message
      final success = await _authService.signInWithEmailAndPassword(email, password);
      
      if (success) {
        // Safely get user info after sign-in
        await Future.delayed(const Duration(milliseconds: 500));
        _user = await _authService.getCurrentUser();
        
        if (_user != null) {
          _role = await _roleService.getUserRole(_user!.uid);
          print('Sign in successful and user data loaded. Role: $_role');
        } else {
          print('Warning: User signed in but getCurrentUser returned null');
        }
      } else {
        _error = 'Login failed. Please check your credentials.';
      }
      
      _isLoading = false;
      notifyListeners();
      return success && _user != null;
    } catch (e) {
      _isLoading = false;
      // Ignore PigeonUserDetails errors completely
      if (e.toString().contains('PigeonUserDetails')) {
        // If we get this error, check if we're actually signed in
        final signedIn = _authService.currentUser != null;
        
        if (!signedIn) {
          _error = 'Login failed. Please check your credentials.';
        }
        
        notifyListeners();
        return signedIn;
      } else {
        _error = 'An unexpected error occurred during sign in.';
        notifyListeners();
        return false;
      }
    }
  }
  
  // Initialize the current user on startup - with logging
  Future<void> _initCurrentUser() async {
    try {
      final UserModel? previousUser = _user;
      _user = await _authService.getCurrentUser();
      
      if (_user != null) {
        _role = await _roleService.getUserRole(_user!.uid);
        print('User initialized: ${_user!.email}, role: $_role');
      } else if (previousUser != null) {
        print('Warning: _initCurrentUser cleared an existing user');
      }
      
      notifyListeners();
    } catch (e) {
      print('Error initializing current user: $e');
    }
  }

  // Register with email and password with better error handling
  Future<bool> register(String email, String password, {String name = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Register user with email and password
      final success = await _authService.registerWithEmailAndPassword(email, password, name: name);
      // The AuthService should handle creating the Firestore user document and setting displayName
      _isLoading = false;
      notifyListeners();
      return success;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred during registration.';
      notifyListeners();
      return false;
    }
  }

  // Sign out - prevent accidental sign-outs
  Future<void> signOut() async {
    try {
      print('Explicitly signing out user: ${_user?.email}');
      
      // Set state variables to null AFTER Firebase sign-out
      await _authService.signOut();
      
      _user = null;
      _role = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to sign out: $e';
      print('Sign out error: $e');
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Handle Firebase Auth specific errors
  void _handleAuthError(FirebaseAuthException e) {
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
      case 'email-already-in-use':
        _error = 'Email is already in use.';
        break;
      case 'weak-password':
        _error = 'Password is too weak.';
        break;
      case 'operation-not-allowed':
        _error = 'Email/password accounts are not enabled.';
        break;
      default:
        _error = 'Authentication error: ${e.message}';
    }
    notifyListeners();
  }
}
