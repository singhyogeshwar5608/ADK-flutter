import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryUploadResult {
  CloudinaryUploadResult({required this.url, required this.publicId});

  final String url;
  final String publicId;
}

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  String get _cloudName =>
      _env('CLOUDINARY_CLOUD_NAME', fallbackKey: 'CLOUD_NAME');
  String get _uploadPreset =>
      _env('CLOUDINARY_UPLOAD_PRESET', fallbackKey: 'CLOUD_PRESET');
  String get _uploadUrl => _env(
        'CLOUDINARY_UPLOAD_URL',
        fallbackValue:
            'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

  String _env(String key, {String? fallbackKey, String fallbackValue = ''}) {
    final value = dotenv.env[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    if (fallbackKey != null) {
      final fallback = dotenv.env[fallbackKey];
      if (fallback != null && fallback.isNotEmpty) {
        return fallback;
      }
    }
    return fallbackValue;
  }

  bool get _hasRequiredConfig {
    print('Cloudinary Debug: cloudName="$_cloudName", preset="$_uploadPreset"');
    return _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;
  }

  Future<CloudinaryUploadResult> uploadImage(
      {File? file, Uint8List? bytes, String? filename}) async {
    if (!_hasRequiredConfig) {
      throw CloudinaryException(
          'Missing Cloudinary configuration. Please ensure CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET are set in .env file. Current: cloudName="$_cloudName", preset="$_uploadPreset"');
    }
    if (file == null && (bytes == null || bytes.isEmpty)) {
      throw const CloudinaryException('No image provided');
    }

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['upload_preset'] = _uploadPreset;

    if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    } else {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes!,
        filename: filename ?? 'upload.jpg',
      ));
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final url = (json['secure_url'] ?? json['url']) as String?;
      final publicId = json['public_id'] as String?;
      if (url == null || publicId == null) {
        throw const CloudinaryException('Malformed upload response');
      }
      return CloudinaryUploadResult(url: url, publicId: publicId);
    }
    throw CloudinaryException(
        'Upload failed: ${response.statusCode} - ${response.body}');
  }

  // Temporary placeholder until secure backend deletion endpoint is available.
  // Future<void> deleteImage(String publicId) async {
  //   throw UnimplementedError('Image deletion must be handled server-side for security.');
  // }
}

class CloudinaryException implements Exception {
  const CloudinaryException(this.message);
  final String message;

  @override
  String toString() => 'CloudinaryException: $message';
}
