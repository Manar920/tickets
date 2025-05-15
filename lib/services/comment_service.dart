import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment_model.dart';
import 'storage_service.dart';
import 'role_service.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final RoleService _roleService = RoleService();
  
  // Collection references
  CollectionReference get _commentsCollection => _firestore.collection('comments');
  
  // Stream of comments for a specific ticket
  Stream<List<CommentModel>> getTicketComments(String ticketId) {
    return _commentsCollection
      .where('ticketId', isEqualTo: ticketId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CommentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
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
      
      // Save to Firestore
      final docRef = await _commentsCollection.add(commentWithAttachments.toMap());
      
      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }
  
  // Delete a comment (only if user is owner or admin)
  Future<void> deleteComment(String commentId, String userId) async {
    try {
      // Get the comment
      final commentDoc = await _commentsCollection.doc(commentId).get();
      
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }
      
      final commentData = commentDoc.data() as Map<String, dynamic>;
      
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
          await _storageService.deleteFile(url.toString());
        } catch (e) {
          print('Error deleting attachment: $e');
          // Continue with other deletions even if one fails
        }
      }
      
      // Delete comment document
      await _commentsCollection.doc(commentId).delete();
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
