import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';


class CommentProvider with ChangeNotifier {
  final CommentService _commentService = CommentService();
  
  
  List<CommentModel> _comments = [];
  bool _isLoading = false;
  String? _error;
  String? _currentTicketId;
  
  // Subscriptions
  Stream<List<CommentModel>>? _commentsStream;
  bool _disposed = false;
  
  // Getters
  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;
    // Set the current ticket ID and listen to comments
  void setCurrentTicket(String ticketId) {
    if (ticketId == _currentTicketId) return;
    
    _currentTicketId = ticketId;
    
    
    Future.microtask(() => _loadComments());
  }
  
  
  void _loadComments() {
    if (_disposed || _currentTicketId == null) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      
      _commentsStream = _commentService.getTicketComments(_currentTicketId!);
      
      
      _commentsStream!.listen((commentsList) {
        if (!_disposed) {
          _comments = commentsList;
          _isLoading = false;
          notifyListeners();
        }
      }, onError: (e) {
        if (!_disposed) {
          _error = 'Error loading comments: $e';
          _isLoading = false;
          notifyListeners();
        }
      });
    } catch (e) {
      if (!_disposed) {
        _error = 'Error setting up comments: $e';
        _isLoading = false;
        notifyListeners();
      }
    }
  }
  
  
  Future<String?> addComment(String message, List<File>? attachments) async {
    if (_disposed || _currentTicketId == null) return null;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      
      final userRole = await _commentService.getUserRole(user.uid);
      
      
      final comment = CommentModel(
        ticketId: _currentTicketId!,
        userId: user.uid,
        userEmail: user.email ?? 'unknown@email.com',
        userRole: userRole,
        message: message,
        createdAt: DateTime.now(),
      );
      
      
      final commentId = await _commentService.addComment(comment, attachments);
      
      _isLoading = false;
      notifyListeners();
      
      return commentId;
    } catch (e) {
      if (!_disposed) {
        _error = 'Failed to add comment: $e';
        _isLoading = false;
        notifyListeners();
      }
      return null;
    }
  }
  
  
  Future<bool> deleteComment(String commentId) async {
    if (_disposed) return false;
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      await _commentService.deleteComment(commentId, user.uid);
      
      _isLoading = false;
      notifyListeners();
      
      return true;
    } catch (e) {
      if (!_disposed) {
        _error = 'Failed to delete comment: $e';
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }
  
  
  void clearError() {
    if (_disposed) return;
    
    _error = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
