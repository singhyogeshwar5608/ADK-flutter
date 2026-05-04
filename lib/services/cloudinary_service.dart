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
  // Public upload settings fallback for web when dotenv asset fails to load.
  static const String _defaultCloudName = 'dtnuwjtt3';
  static const String _defaultUploadPreset = 'ADK_preset';

  String get _cloudName => _firstEnvValue([
        'CLOUDINARY_CLOUD_NAME',
        'CLOUD_NAME',
        'VITE_CLOUDINARY_CLOUD_NAME',
        'VITE_CLOUD_NAME',
      ], fallback: _defaultCloudName);
  String get _uploadPreset => _firstEnvValue([
        'CLOUDINARY_UPLOAD_PRESET',
        'CLOUD_PRESET',
        'VITE_CLOUDINARY_UPLOAD_PRESET',
        'VITE_CLOUD_PRESET',
      ], fallback: _defaultUploadPreset);
  String get _uploadUrl {
    final configured = _firstEnvValue([
      'CLOUDINARY_UPLOAD_URL',
      'VITE_CLOUDINARY_UPLOAD_URL',
    ]);
    if (configured.isNotEmpty) return configured;
    if (_cloudName.isEmpty) return '';
    return 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  }

  String _firstEnvValue(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final raw = dotenv.env[key];
      if (raw == null) continue;
      final value = raw.trim();
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  bool get _hasRequiredConfig {
    print('Cloudinary Debug: cloudName="$_cloudName", preset="$_uploadPreset"');
    return _cloudName.isNotEmpty &&
        _uploadPreset.isNotEmpty &&
        _uploadUrl.isNotEmpty;
  }

  Future<CloudinaryUploadResult> uploadImage(
      {File? file, Uint8List? bytes, String? filename}) async {
    if (!_hasRequiredConfig) {
      throw CloudinaryException(
          'Missing Cloudinary configuration. Ensure CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET are set in assets/dotenv (or VITE_* variants). Current: cloudName="$_cloudName", preset="$_uploadPreset", uploadUrl="$_uploadUrl"');
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
