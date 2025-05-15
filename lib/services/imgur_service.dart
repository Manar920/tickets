import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ImgurService {
  static const String _apiUrl = 'https://api.imgur.com/3/image';
  static const String _clientId = '65b7fdfad389879';
  static const String _clientSecret = '4beea3f967c91f291699a4ac6c205036ff82979c';

  /// Uploads an image to Imgur and returns the URL
  Future<String?> uploadImage(File imageFile) async {
    try {
      // Convert the image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Create the request
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      
      // Add image data
      request.fields['image'] = base64Image;
      
      // Set headers with client ID for authorization
      request.headers['Authorization'] = 'Client-ID $_clientId';
      
      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final parsed = jsonDecode(responseData);
      
      // Check if upload was successful
      if (response.statusCode == 200 && parsed['success'] == true) {
        final imageUrl = parsed['data']['link'];
        print('Successfully uploaded image to Imgur: $imageUrl');
        return imageUrl;
      } else {
        print('Failed to upload image to Imgur. Status: ${response.statusCode}');
        print('Response: $responseData');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Imgur: $e');
      return null;
    }
  }

  /// Uploads an image to Imgur using form data (alternative method)
  Future<String?> uploadImageFormData(File imageFile) async {
    try {
      final extension = path.extension(imageFile.path).toLowerCase();
      final filename = path.basename(imageFile.path);
      
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
      
      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: filename,
        ),
      );
      
      // Set headers
      request.headers['Authorization'] = 'Client-ID $_clientId';
      
      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final parsed = jsonDecode(responseData);
      
      // Check if upload was successful
      if (response.statusCode == 200 && parsed['success'] == true) {
        final imageUrl = parsed['data']['link'];
        print('Successfully uploaded image to Imgur: $imageUrl');
        return imageUrl;
      } else {
        print('Failed to upload image to Imgur. Status: ${response.statusCode}');
        print('Response: $responseData');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Imgur (FormData): $e');
      return null;
    }
  }
  
  /// Delete an image from Imgur (requires hash from the URL)
  Future<bool> deleteImage(String deleteHash) async {
    try {
      final url = 'https://api.imgur.com/3/image/$deleteHash';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Client-ID $_clientId',
        },
      );
      
      final parsed = jsonDecode(response.body);
      
      if (response.statusCode == 200 && parsed['success'] == true) {
        print('Successfully deleted Imgur image');
        return true;
      } else {
        print('Failed to delete Imgur image. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting Imgur image: $e');
      return false;
    }
  }
  
  /// Extract delete hash from Imgur response (store this to enable deletion later)
  String? extractDeleteHash(String responseBody) {
    try {
      final parsed = jsonDecode(responseBody);
      return parsed['data']['deletehash'];
    } catch (e) {
      print('Error extracting delete hash: $e');
      return null;
    }
  }
}
