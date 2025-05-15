import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import 'storage_service.dart';
import 'role_service.dart';

class CommentService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final StorageService _storageService = StorageService();
  final RoleService _roleService = RoleService();
  
  // Reference to comments node in the database
  DatabaseReference get _commentsRef => _database.ref().child('comments');
  
  // Stream of comments for a specific ticket
  Stream<List<CommentModel>> getTicketComments(String ticketId) {
    return _commentsRef
      .orderByChild('ticketId')
      .equalTo(ticketId)
      .onValue
      .map((event) {
        final snapshot = event.snapshot;
        if (snapshot.value == null) return [];
        
        final commentsMap = snapshot.value as Map<dynamic, dynamic>;
        final commentsList = <CommentModel>[];
        
        commentsMap.forEach((key, value) {
          // Convert each comment data to CommentModel
          commentsList.add(CommentModel.fromMap(
            Map<String, dynamic>.from(value as Map), 
            key.toString(),
          ));
        });
        
        // Sort by createdAt timestamp (oldest first)
        commentsList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return commentsList;
      });
  }
    // Add a new comment
  Future<String> addComment(CommentModel comment, List<File>? attachments) async {
    try {
      // If attachments provided, upload them first
      List<String> attachmentUrls = [];
      
      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          try {
            final url = await _storageService.uploadFile(
              file,
              'comments/${comment.ticketId}/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}'
            );
            if (url != null) {
              attachmentUrls.add(url);
            }
          } catch (e) {
            print('Error uploading attachment: $e');
            // Continue with other uploads even if one fails
          }
        }
      }
      
      // Create comment with attachment URLs
      final commentWithAttachments = comment.copyWith(
        attachmentUrls: attachmentUrls,
      );
      
      // Get a new key for the comment
      final newCommentRef = _commentsRef.push();
      
      // Save to Realtime Database
      await newCommentRef.set(commentWithAttachments.toMap());
      
      return newCommentRef.key!;
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }
    // Delete a comment (only if user is owner or admin)
  Future<void> deleteComment(String commentId, String userId) async {
    try {
      // Get the comment data
      final commentSnapshot = await _commentsRef.child(commentId).get();
      
      if (!commentSnapshot.exists) {
        throw Exception('Comment not found');
      }
      
      final commentData = Map<String, dynamic>.from(commentSnapshot.value as Map);
      
      // Check if user is owner or admin
      final isAdmin = await _roleService.isUserAdmin(userId);
      final isOwner = commentData['userId'] == userId;
      
      if (!isAdmin && !isOwner) {
        throw Exception('Not authorized to delete this comment');
      }
      
      // Delete attachments from storage
      final attachmentUrls = commentData['attachmentUrls'] as List<dynamic>? ?? [];
      for (var url in attachmentUrls) {
        try {
          final success = await _storageService.deleteFile(url.toString());
          if (!success) {
            print('Warning: Could not delete attachment: $url');
            // Continue with other deletions even if one fails
          }
        } catch (e) {
          print('Error deleting attachment: $e');
          // Continue with other deletions even if one fails
        }
      }
      
      // Delete comment from database
      await _commentsRef.child(commentId).remove();
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Failed to delete comment: $e');
    }
  }
  
  // Helper method to get user role for new comments
  Future<String> getUserRole(String userId) async {
    final isAdmin = await _roleService.isUserAdmin(userId);
    return isAdmin ? 'admin' : 'client';
  }
}
