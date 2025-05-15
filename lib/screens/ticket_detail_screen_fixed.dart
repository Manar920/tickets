// filepath: c:\Users\Borhen\Documents\ticketsapp\tickets\lib\screens\ticket_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/ticket_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_provider.dart';
import '../models/ticket_model.dart';
import '../services/auth_service.dart';
import '../widgets/ticket_status_changer.dart';
import '../widgets/comment_bubble.dart';
import '../widgets/comment_input.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final bool isAdmin;

  const TicketDetailScreen({
    Key? key,
    required this.ticketId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  TicketModel? _ticket;
  bool _isLoading = true;
  String? _error;
  String? _clientEmail;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      final ticket = await ticketProvider.getTicket(widget.ticketId);
      
      if (ticket != null && widget.isAdmin) {
        // Only try to get client email if admin view
        try {
          final clientDoc = await _authService.getUserInfo(ticket.clientId);
          if (clientDoc != null && clientDoc.containsKey('email')) {
            _clientEmail = clientDoc['email'];
          }
        } catch (e) {
          print('Error fetching client info: $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load ticket: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Helper methods for UI
  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }
  
  bool _isPlaceholderUrl(String url) {
    return url.startsWith('asset://') || 
           url.contains('unavailable') || 
           url.contains('failed');
  }
  
  String _getActualImageUrl(String url) {
    // If it's an asset URL, return just the path part
    if (url.startsWith('asset://')) {
      return url.substring(8); // Remove the 'asset://' prefix
    }
    return url;
  }
  
  bool _isAssetUrl(String url) {
    return url.startsWith('asset://');
  }
  
  // Ticket status update action
  Future<void> _updateTicketStatus(String newStatus) async {
    if (_ticket == null) return;
    
    try {
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Make sure user is available
      if (authProvider.user == null) {
        throw Exception('User not authenticated');
      }
      
      final updatedTicket = _ticket!.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        assignedToId: widget.isAdmin ? (_ticket!.assignedToId ?? authProvider.user!.uid) : _ticket!.assignedToId,
      );
      
      await ticketProvider.updateTicket(updatedTicket);
      
      if (mounted) {
        setState(() {
          _ticket = updatedTicket;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket status updated to ${_formatStatus(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTicket() async {
    if (!widget.isAdmin || _ticket?.id == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ticket'),
        content: const Text('Are you sure you want to delete this ticket? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false; // Default to false if dialog is dismissed
    
    if (confirmed && mounted) {
      try {
        final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
        await ticketProvider.deleteTicket(_ticket!.id!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete ticket: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Image handling
  void _viewAttachment(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Image'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: url.startsWith('asset://') 
                  ? Image.asset(
                      url.substring(8), // Remove 'asset://' prefix
                      fit: BoxFit.contain,
                    )
                  : Image.network(
                      url,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 100, color: Colors.red),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check if a URL is an image
  bool _isImageUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.endsWith('.jpg') || 
           lowerUrl.endsWith('.jpeg') ||
           lowerUrl.endsWith('.png') ||
           lowerUrl.endsWith('.gif') ||
           lowerUrl.endsWith('.webp');
  }
  
  // Get file icon based on extension
  IconData _getFileIcon(String url) {
    final extension = _getFileExtension(url).toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.article;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  // Get file extension from URL
  String _getFileExtension(String url) {
    final Uri uri = Uri.parse(url);
    final String path = uri.path;
    final int lastDot = path.lastIndexOf('.');
    
    if (lastDot != -1 && lastDot < path.length - 1) {
      return path.substring(lastDot + 1);
    }
    return 'file';
  }
  
  // Download attachment
  void _downloadAttachment(String url) {
    // Implementation would use url_launcher or file_downloader package
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download feature will be implemented in the next update'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // UI Components
  Widget _buildAttachmentsSection() {
    if (_ticket == null || _ticket!.attachmentUrls.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attachments',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Text('No attachments available'),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments (${_ticket!.attachmentUrls.length})',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _ticket!.attachmentUrls.length,
            itemBuilder: (context, index) {
              final url = _ticket!.attachmentUrls[index];
              final isPlaceholder = _isPlaceholderUrl(url);
              final isImage = _isImageUrl(url);
              
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _viewAttachment(context, url),
                    child: Container(
                      width: 140,
                      height: 140,
                      color: Colors.grey.shade200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // File preview
                          isImage
                            ? url.startsWith('asset://') 
                              ? Image.asset(
                                  url.substring(8), // Remove 'asset://' prefix
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  url,
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, __) {
                                    print('Error displaying image: $error');
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, color: Colors.red, size: 40),
                                          SizedBox(height: 4),
                                          Text('Image Error', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  },
                                )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(_getFileIcon(url), size: 50, color: Colors.grey.shade700),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getFileExtension(url).toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                          // Placeholder indicator
                          if (isPlaceholder)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                color: Colors.red,
                                padding: const EdgeInsets.all(4),
                                child: const Text(
                                  'PLACEHOLDER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            
                          // Download button
                          if (!isPlaceholder && !url.startsWith('asset://'))
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Material(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () => _downloadAttachment(url),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.download,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Build comments section
  Widget _buildCommentsSection() {
    return ChangeNotifierProvider(
      create: (_) => CommentProvider(),
      child: Builder(
        builder: (context) {
          final commentProvider = Provider.of<CommentProvider>(context);
          final authProvider = Provider.of<AuthProvider>(context);
          
          // Set the current ticket ID for the comments provider
          if (_ticket != null) {
            // This will trigger loading comments if needed
            commentProvider.setCurrentTicket(_ticket!.id!);
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comments heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Discussion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (commentProvider.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Comments list
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Comments list
                    commentProvider.comments.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: const Text(
                              'No messages yet. Be the first to comment!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: commentProvider.comments.length,
                              itemBuilder: (context, index) {
                                final comment = commentProvider.comments[index];
                                final isCurrentUser = comment.userId == authProvider.user?.uid;
                                return CommentBubble(
                                  comment: comment,
                                  isCurrentUser: isCurrentUser,
                                  onDelete: isCurrentUser
                                      ? () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Delete Comment'),
                                              content: const Text('Are you sure you want to delete this comment?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          ) ?? false;
                                          
                                          if (confirm && comment.id != null) {
                                            await commentProvider.deleteComment(comment.id!);
                                          }
                                        }
                                      : null,
                                );
                              },
                            ),
                          ),
                    
                    // Error message if any
                    if (commentProvider.error != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          commentProvider.error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Comment input
                    if (_ticket != null && _ticket!.status != 'closed')
                      CommentInput(
                        ticketId: _ticket!.id!,
                      ),
                    
                    // Cannot comment message if ticket is closed
                    if (_ticket != null && _ticket!.status == 'closed')
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Text(
                          'This ticket is closed. You cannot add new comments.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_ticket?.title ?? 'Ticket Details'),
        actions: [
          if (widget.isAdmin && _ticket != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTicket,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTicket,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _ticket == null
                  ? const Center(child: Text('Ticket not found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ticket header with title and status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _ticket!.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_ticket!.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _formatStatus(_ticket!.status),
                                  style: TextStyle(
                                    color: _getStatusColor(_ticket!.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Created/updated dates
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Created on ${DateFormat('MMM dd, yyyy – HH:mm').format(_ticket!.createdAt)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (_ticket!.updatedAt != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.update,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Updated on ${DateFormat('MMM dd, yyyy – HH:mm').format(_ticket!.updatedAt!)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          
                          // Priority
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(_ticket!.priority).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Priority: ${_ticket!.priority.substring(0, 1).toUpperCase() + _ticket!.priority.substring(1)}',
                              style: TextStyle(
                                color: _getPriorityColor(_ticket!.priority),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Client information (only for admin view)
                          if (widget.isAdmin) ...[
                            const SizedBox(height: 16),
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Client Information',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.person, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Client ID: ${_ticket!.clientId}',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_clientEmail != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.email, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Email: $_clientEmail',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          // Description
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              _ticket!.description,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          
                          // Status update controls for all users
                          const SizedBox(height: 24),
                          TicketStatusChanger(
                            ticket: _ticket!,
                            onStatusChanged: _updateTicketStatus,
                          ),
                          
                          const SizedBox(height: 24),
                          _buildAttachmentsSection(),

                          // Comments section
                          const SizedBox(height: 24),
                          _buildCommentsSection(),
                        ],
                      ),
                    ),
    );
  }
}
