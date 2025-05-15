import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'imgur_service.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImgurService _imgurService = ImgurService();
  
  // Set to true to skip real uploads and just use placeholders during development
  final bool _useMockMode = false; // Set to false to use real uploads
  
  // Use Imgur instead of Firebase Storage
  final bool _useImgur = true; // Set to true to use Imgur, false to use Firebase
  
  // Ultra-reliable upload method
  Future<String> uploadFile(File file, String path) async {
    // In mock mode, immediately return a placeholder without trying real upload
    if (_useMockMode) {
      print('Mock mode enabled - skipping real upload');
      return _getFallbackImageUrl();
    }
    
    try {
      // If using Imgur, delegate to the Imgur service
      if (_useImgur) {
        return await _uploadToImgur(file);
      } else {
        return await _uploadToFirebase(file, path);
      }
    } catch (e) {
      print('Fatal error in upload: $e');
      return _getFallbackImageUrl();
    }
  }
  // Upload to Imgur
  Future<String> _uploadToImgur(File file) async {
    try {
      print('Uploading to Imgur: ${file.path}');
      
      // Check file size - Imgur limits uploads to 10MB for anonymous uploads
      final fileSize = await file.length();
      final fileSizeInMB = fileSize / (1024 * 1024);
      
      if (fileSizeInMB > 10) {
        print('Warning: File size ${fileSizeInMB.toStringAsFixed(1)}MB exceeds Imgur\'s 10MB limit');
        return _getFallbackImageUrl();
      }
      
      // Set a timeout but increase to 15 seconds for slower connections
      final result = await Future.any([
        _imgurService.uploadImageFormData(file),
        // Timeout after 15 seconds
        Future.delayed(const Duration(seconds: 15))
            .then((_) => throw TimeoutException('Imgur upload timed out after 15 seconds'))
      ]);
      
      if (result != null) {
        print('Successfully uploaded to Imgur: $result');
        return result;
      } else {
        print('Imgur upload failed with null response');
        return _getFallbackImageUrl();
      }
    } catch (e) {
      print('Imgur upload failed: $e');
      
      // Additional debugging
      if (e is TimeoutException) {
        print('File upload timed out. Consider checking your network connection.');
      }
      
      return _getFallbackImageUrl();
    }  }
  
  // Upload to Firebase Storage
  Future<String> _uploadToFirebase(File file, String path) async {
    try {
      // Extract userId from path
      String userId = path.split('/').first;
      // Simple filename - convert to all lowercase to avoid issues
      final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('Uploading to Firebase: $fileName');
      
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
  }  // Return a fallback image URL - these are local assets
  String _getFallbackImageUrl() {
    final placeholders = [
      'asset://assets/images/placeholder_unavailable.png',
      'asset://assets/images/placeholder_failed.png',
      'asset://assets/images/placeholder_retry.png'
    ];
    return placeholders[Random().nextInt(placeholders.length)];
  }
  
  // Upload multiple files with guaranteed completion
  Future<List<String>> uploadFiles(List<File> files, String path) async {
    print('Processing ${files.length} attachments');
    
    if (files.isEmpty) return [];
    
    List<String> urls = [];
    int successCount = 0;
    
    // Process each file with individual timeout
    for (int i = 0; i < files.length; i++) {
      try {
        print('Uploading attachment ${i+1}/${files.length}');
        // Get a URL one way or another with a longer timeout
        String url = await uploadFile(files[i], path)
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
  
  // Delete a file from Firebase Storage or Imgur
  Future<bool> deleteFile(String url) async {
    try {
      // Skip deletion for asset placeholder URLs
      if (url.startsWith('asset://')) {
        print('Skipping deletion for placeholder asset URL');
        return true;
      }
      
      // Determine if this is an Imgur URL or Firebase URL
      if (_useImgur && url.contains('imgur.com')) {
        print('Attempting to delete Imgur image: $url');
        // We can't delete from Imgur without the delete hash (which we don't store yet)
        print('Note: Deletion from Imgur not fully implemented - image will remain on Imgur');
        return true;
      } else {
        // Extract the storage reference from the URL
        try {
          // Create a reference from the download URL
          final ref = FirebaseStorage.instance.refFromURL(url);
          
          // Delete the file
          await ref.delete();
          print('Successfully deleted file from Firebase: ${ref.fullPath}');
          return true;
        } catch (e) {
          print('Error deleting file from URL $url: $e');
          return false;
        }
      }
    } catch (e) {
      print('Failed to delete file: $e');
      return false;
    }
  }
}

// Custom exception for timeouts
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => 'TimeoutException: $message';
}
