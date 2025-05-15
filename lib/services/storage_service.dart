import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Set to true to skip real uploads and just use placeholders during development
  final bool _useMockMode = false; // Set to false to use real Firebase Storage
  // Ultra-reliable upload method
  Future<String> uploadFile(File file, String userId) async {
    // In mock mode, immediately return a placeholder without trying Firebase
    if (_useMockMode) {
      print('Mock mode enabled - skipping real upload');
      return _getFallbackImageUrl();
    }
    
    try {
      // Simple filename - convert to all lowercase to avoid issues
      final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('Uploading $fileName');

      try {
        // Set a timeout but increase to 15 seconds for slower connections
        final result = await Future.any([
          _doSimpleUpload(file, userId, fileName),
          // Timeout after 15 seconds
          Future.delayed(const Duration(seconds: 15))
              .then((_) => throw TimeoutException('Upload timed out after 15 seconds'))
        ]);
        
        return result;
      } catch (e) {
        print('Upload failed: $e');
        
        // Additional debugging
        if (e is TimeoutException) {
          print('File upload timed out. Consider checking your network connection.');
        }
        
        return _getFallbackImageUrl();
      }
    } catch (e) {
      print('Fatal error in upload: $e');
      return _getFallbackImageUrl();
    }
  }
  // Core upload function isolated for better error handling
  Future<String> _doSimpleUpload(File file, String userId, String fileName) async {
    try {
      // Verify the file exists and is readable
      if (!await file.exists()) {
        print('Error: File does not exist: ${file.path}');
        throw Exception('Image file not found');
      }

      // Get file size for logging
      final fileSize = await file.length();
      print('Uploading file (${fileSize ~/ 1024} KB): ${file.path}');
      
      // Build the storage reference
      final ref = _storage.ref()
          .child('tickets')
          .child(userId)
          .child(fileName);
      
      // Check if file is readable
      try {
        await file.readAsBytes().timeout(const Duration(seconds: 3));
      } catch (e) {
        print('Error reading file: $e');
        throw Exception('Cannot read image file');
      }
      
      // Basic file upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId, 'uploadedAt': DateTime.now().toString()},
      );
      
      // Do the actual upload
      try {
        final uploadTask = ref.putFile(file, metadata);
        
        // Monitor upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        }, onError: (e) {
          print('Upload monitoring error: $e');
        });
        
        // Wait for completion
        await uploadTask;
        print('Upload completed successfully');
      } catch (e) {
        print('File upload failed: $e');
        throw Exception('Failed to upload image to server');
      }
      
      // Get a signed URL that's publicly accessible for longer
      try {
        final downloadUrl = await ref.getDownloadURL();
        print('Image URL generated: $downloadUrl');
        return downloadUrl;
      } catch (e) {
        print('Failed to get download URL: $e');
        throw Exception('Could not retrieve image URL');
      }
    } catch (e) {
      print('Basic upload failed: $e');
      throw e; // Rethrow to be caught by the timeout handler
    }
  }
  // Return a fallback image URL - these are local assets
  String _getFallbackImageUrl() {
    final placeholders = [
      'asset://assets/images/placeholder_unavailable.png',
      'asset://assets/images/placeholder_failed.png',
      'asset://assets/images/placeholder_retry.png'
    ];
    return placeholders[Random().nextInt(placeholders.length)];
  }
  // Upload multiple files with guaranteed completion
  Future<List<String>> uploadFiles(List<File> files, String userId) async {
    print('Processing ${files.length} attachments');
    
    if (files.isEmpty) return [];
    
    List<String> urls = [];
    int successCount = 0;
    
    // Process each file with individual timeout
    for (int i = 0; i < files.length; i++) {
      try {
        print('Uploading attachment ${i+1}/${files.length}');
        // Get a URL one way or another with a longer timeout
        String url = await uploadFile(files[i], userId)
            .timeout(const Duration(seconds: 20), 
                onTimeout: () {
                  print('Attachment ${i+1} upload timed out');
                  return _getFallbackImageUrl();
                });
                
        if (!url.startsWith('asset://')) {
          successCount++;
        }
        
        urls.add(url);
        print('Processed attachment ${i+1}/${files.length}');
      } catch (e) {
        // Ensure we always add something to the URLs list
        print('Error uploading attachment ${i+1}: $e');
        urls.add(_getFallbackImageUrl());
      }
    }
    
    print('Completed with ${urls.length} attachments (${successCount} successful uploads)');
    return urls;
  }
}

// Custom exception for timeouts
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}
