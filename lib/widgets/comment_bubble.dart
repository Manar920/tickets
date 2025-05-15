import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/comment_model.dart';

class CommentBubble extends StatelessWidget {
  final CommentModel comment;
  final bool isCurrentUser;
  final Function()? onDelete;
  
  const CommentBubble({
    Key? key,
    required this.comment,
    required this.isCurrentUser,
    this.onDelete,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Determine alignment and colors based on who sent the message
    final alignment = isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    
    // Choose colors based on user role and whether it's the current user
    Color bubbleColor;
    Color textColor = Colors.black87;
    
    if (isCurrentUser) {
      bubbleColor = Colors.blue.shade100;
    } else {
      switch (comment.userRole) {
        case 'admin':
          bubbleColor = Colors.purple.shade100;
          break;
        case 'support':
          bubbleColor = Colors.amber.shade100;
          break;
        default:
          bubbleColor = Colors.grey.shade100;
      }
    }
    
    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message header with user info and timestamp
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(comment.userRole),
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  isCurrentUser ? 'You' : comment.userEmail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, HH:mm').format(comment.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
                if (isCurrentUser && onDelete != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: Colors.red[300],
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                comment.message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
            
            // Attachments (if any)
            if (comment.attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: comment.attachmentUrls.length,
                  itemBuilder: (context, index) {
                    final url = comment.attachmentUrls[index];
                    return GestureDetector(
                      onTap: () => _viewAttachment(context, url),
                      child: Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _getAttachmentPreview(url),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Helper method to get icon based on user role
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'support':
        return Icons.support_agent;
      default:
        return Icons.person;
    }
  }
  
  // Helper method to get attachment preview
  Widget _getAttachmentPreview(String url) {
    if (url.toLowerCase().endsWith('.jpg') || 
        url.toLowerCase().endsWith('.jpeg') || 
        url.toLowerCase().endsWith('.png')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else {
      return const Icon(Icons.attach_file);
    }
  }
  
  // View attachment in full screen
  void _viewAttachment(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Attachment'),
            backgroundColor: Colors.black,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                url,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 100, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
