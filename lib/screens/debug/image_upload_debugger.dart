import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class ImageUploadDebugger extends StatefulWidget {
  const ImageUploadDebugger({Key? key}) : super(key: key);

  @override
  State<ImageUploadDebugger> createState() => _ImageUploadDebuggerState();
}

class _ImageUploadDebuggerState extends State<ImageUploadDebugger> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;
  String? _resultUrl;
  String? _error;
  
  Future<void> _testImageUpload(File file, String userId) async {
    setState(() {
      _isUploading = true;
      _resultUrl = null;
      _error = null;
    });
      try {
      final url = await _storageService.uploadFile(file, 'debug/$userId');
      
      setState(() {
        _resultUrl = url;
        _isUploading = false;
      });
      
      print('Debug upload result: $url');
    } catch (e) {
      setState(() {
        _error = 'Upload failed: $e';
        _isUploading = false;
      });
      print('Debug upload error: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Upload Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Image Upload',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (_isUploading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Uploading image...'),
                ],
              )
            else if (_resultUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upload successful!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('URL: $_resultUrl'),
                  const SizedBox(height: 16),
                  
                  const Text('Image preview:'),
                  const SizedBox(height: 8),
                  _resultUrl!.startsWith('asset://')
                    ? Image.asset(
                        _resultUrl!.substring(8),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      )
                    : Image.network(
                        _resultUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, e, __) => Text('Failed to load image: $e'),
                      ),
                ],
              )
            else if (_error != null)
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              )
            else
              const Text('Press button below to test image upload'),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: authProvider.user == null
                ? null
                : () {
                    // This is a debug function - don't use in production
                    // This will create a test file and try to upload it
                    final tempDir = Directory.systemTemp;
                    final testFile = File('${tempDir.path}/test_image.jpg');
                    // Write some bytes to the file to simulate an image
                    testFile.writeAsBytes([1, 2, 3, 4, 5]);
                    _testImageUpload(testFile, authProvider.user!.uid);
                  },
              child: const Text('Test Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
