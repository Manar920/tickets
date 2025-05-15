import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/comment_provider.dart';

class CommentInput extends StatefulWidget {
  final String ticketId;
  
  const CommentInput({
    Key? key,
    required this.ticketId,
  }) : super(key: key);
  
  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _messageController = TextEditingController();
  final List<File> _attachments = [];
  bool _isSubmitting = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
  
  // Pick an image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() {
          _attachments.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Remove an attachment
  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }
  
  // Send the comment
  Future<void> _sendComment() async {
    String message = _messageController.text.trim();
    if (message.isEmpty && _attachments.isEmpty) return;
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final commentProvider = Provider.of<CommentProvider>(context, listen: false);
      
      // Set the current ticket for the comment provider if not already set
      commentProvider.setCurrentTicket(widget.ticketId);
      
      // Add the comment
      final commentId = await commentProvider.addComment(message, _attachments);
      
      if (commentId != null) {
        // Clear input and attachments on success
        _messageController.clear();
        setState(() {
          _attachments.clear();
        });
      } else {
        // Show error if commentId is null
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send comment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending comment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment preview
          if (_attachments.isNotEmpty) ...[
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _attachments.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        margin: const EdgeInsets.only(right: 8, top: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_attachments[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeAttachment(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
          
          Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _isSubmitting ? null : _pickImage,
                color: Colors.blue,
              ),
              
              // Text input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  enabled: !_isSubmitting,
                ),
              ),
              
              // Send button
              IconButton(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _isSubmitting ? null : _sendComment,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
