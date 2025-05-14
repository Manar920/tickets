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
  
  // Initialize the current user on startup
  Future<void> _initCurrentUser() async {
    try {
      _user = await _authService.getCurrentUser();
      if (_user != null) {
        _role = await _roleService.getUserRole(_user!.uid);
      }
      notifyListeners();
    } catch (e) {
      print('Error initializing current user: $e');
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signInWithEmailAndPassword(email, password);
      if (_user != null) {
        _role = await _roleService.getUserRole(_user!.uid);
      }
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
      
      if (e.toString().contains('PigeonUserDetails')) {
        _user = await _authService.getCurrentUser();
        if (_user != null) {
          _role = await _roleService.getUserRole(_user!.uid);
          _error = null;
          notifyListeners();
          return true;
        }
      }
      
      notifyListeners();
      return false;
    }
  }

  // Register with email and password with better error handling
  Future<bool> register(String email, String password, {String name = '', String role = 'client'}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Wait for the registration to complete with name
      _user = await _authService.registerWithEmailAndPassword(
        email, 
        password, 
        name: name,
        role: role
      );
      
      // Explicitly wait a moment to ensure Firestore operation completes
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_user != null) {
        _role = role;
      }
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
      print('Registration general error: $e');
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // First set user to null before calling Firebase signOut
      _user = null;
      _role = null;
      notifyListeners();
      
      // Then sign out from Firebase
      await _authService.signOut();
    } catch (e) {
      _error = 'Failed to sign out: $e';
      print('Sign out error: $e');
      // Don't notify listeners here - might be after disposal
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
