import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/ticket_model.dart';
import 'dart:async';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({Key? key}) : super(key: key);

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'medium';
  bool _isLoading = false;
  List<File> _attachments = [];
  final ImagePicker _picker = ImagePicker();

  // Priority options
  final List<String> _priorityOptions = ['low', 'medium', 'high', 'critical'];

  // Use a flag to track if picker is currently active
  bool _isPickerActive = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  // Pick image from gallery with error handling
  Future<void> _pickImage() async {
    if (_isPickerActive) {
      // Don't open picker if one is already active
      return;
    }
    
    try {
      setState(() {
        _isPickerActive = true;
      });
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Reduce quality slightly to improve upload speed
        maxWidth: 1600,   // Reasonable size for good quality but smaller file
      );
      
      if (image != null && mounted) {
        // Verify the file exists
        final file = File(image.path);
        if (await file.exists()) {
          print('Gallery image selected: ${image.path} (${await file.length()} bytes)');
          setState(() {
            _attachments.add(file);
          });
        } else {
          print('Error: Image file does not exist at path: ${image.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image could not be loaded')),
            );
          }
        }
      }
    } catch (e) {
      // Handle the error gracefully
      print('Error picking image: $e');
      if (e.toString().contains('already_active')) {
        // Just ignore this specific error
      } else if (mounted) {
        // Show other errors in UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickerActive = false;
        });
      }
    }
  }
  // Take a photo with camera with error handling
  Future<void> _takePhoto() async {
    if (_isPickerActive) {
      // Don't open camera if picker is already active
      return;
    }
    
    try {
      setState(() {
        _isPickerActive = true;
      });
      
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Reduce quality slightly to improve upload speed
        maxWidth: 1600,   // Reasonable size for good quality but smaller file
      );
      
      if (photo != null && mounted) {
        // Verify the file exists
        final file = File(photo.path);
        if (await file.exists()) {
          print('Camera photo captured: ${photo.path} (${await file.length()} bytes)');
          setState(() {
            _attachments.add(file);
          });
        } else {
          print('Error: Camera file does not exist at path: ${photo.path}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera image could not be saved')),
            );
          }
        }
      }
    } catch (e) {
      // Handle the error gracefully
      print('Error taking photo: $e');
      if (e.toString().contains('already_active')) {
        // Just ignore this specific error
      } else if (mounted) {
        // Show other errors in UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickerActive = false;
        });
      }
    }
  }

  // Remove attachment at index
  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }
  // Submit the form with improved error handling and timers
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Safety timer to prevent indefinite loading state
      final loadingTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request is taking too long. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
        
        // Check for required values
        if (authProvider.user?.uid == null) {
          throw Exception('User ID is missing. Please log in again.');
        }
        
        // Create ticket model
        final newTicket = TicketModel(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _priority,
          status: 'open',
          clientId: authProvider.user!.uid,
          createdAt: DateTime.now(),
        );
        
        // Create ticket with attachments (with timeout)
        await ticketProvider.createTicket(newTicket, _attachments);
        
        // Cancel safety timer if successful
        loadingTimer.cancel();
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Add delay before popping to ensure snackbar is visible
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        // Cancel safety timer
        loadingTimer.cancel();
        
        print('Error creating ticket: $e');
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create ticket: ${e.toString().split('Exception:').last}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Improved attachment preview with error handling
  Widget _buildAttachmentPreview(File file, int index) {
    try {
      return Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Handle image rendering errors
                  print('Error rendering image: $error');
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: () => _removeAttachment(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      print('Error building attachment preview: $e');
      // Return fallback widget on error
      return Container(
        margin: const EdgeInsets.only(right: 8),
        width: 100,
        height: 100,
        color: Colors.grey.shade200,
        child: Stack(
          children: [
            const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () => _removeAttachment(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Ticket'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Priority dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(),
                      ),
                      value: _priority,
                      items: _priorityOptions.map((priority) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(
                            priority.substring(0, 1).toUpperCase() + priority.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _priority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Attachments section
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Attachment buttons
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _takePhoto,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Attachment previews
                    if (_attachments.isNotEmpty) ...[
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _attachments.length,
                          itemBuilder: (context, index) {
                            return _buildAttachmentPreview(_attachments[index], index);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Submit Ticket',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
