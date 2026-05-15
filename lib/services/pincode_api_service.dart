import 'dart:convert';
import 'package:http/http.dart' as http;

class PincodeApiService {
  static const String _indiaPostUrl = 'https://api.postalpincode.in/pincode';
  static const String _zippopotamUrl = 'https://api.zippopotam.us/IN';

  static Future<Map<String, String>?> getPincodeData(String pincode) async {
    final cleanPincode = pincode.trim();
    if (cleanPincode.length != 6) return null;

    // 1. Try Zippopotam.us first (CORS friendly, works on Web)
    try {
      print('Trying Zippopotam API for $cleanPincode...');
      final response = await http
          .get(Uri.parse('$_zippopotamUrl/$cleanPincode'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['places'] != null && (data['places'] as List).isNotEmpty) {
          final place = data['places'][0];
          final result = {
            'city': place['place name']?.toString() ?? '',
            'state': place['state']?.toString() ?? '',
            'country': 'India',
          };
          print('SUCCESS: Zippopotam found data: $result');
          return result;
        }
      }
    } catch (e) {
      print('Zippopotam API failed: $e');
    }

    // 2. Try India Post API (Original fallback, might fail on Web due to CORS)
    try {
      print('Trying India Post API for $cleanPincode...');
      final response = await http
          .get(Uri.parse('$_indiaPostUrl/$cleanPincode'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        if (responseData.isNotEmpty) {
          final data = responseData[0];
          if (data['Status'] == 'Success' && data['PostOffice'] != null) {
            final postOffices = data['PostOffice'] as List;
            if (postOffices.isNotEmpty) {
              final postOffice = postOffices[0];
              final result = {
                'city': postOffice['District']?.toString() ?? '',
                'state': postOffice['State']?.toString() ?? '',
                'country': postOffice['Country']?.toString() ?? 'India',
              };
              print('SUCCESS: India Post found data: $result');
              return result;
            }
          }
        }
      }
    } catch (e) {
      print('India Post API failed: $e');
    }

    return null;
  }
  
  static Future<List<String>> searchCitiesByPincode(String pincode) async {
    try {
      final response = await http.get(
        Uri.parse('$_indiaPostUrl/$pincode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        
        if (responseData.isNotEmpty) {
          final data = responseData[0];
          if (data['Status'] == 'Success' && data['PostOffice'] != null) {
            final postOffices = data['PostOffice'] as List;
            final cities = postOffices
                .map((office) => office['District'] as String? ?? '')
                .where((city) => city.isNotEmpty)
                .toSet()
                .toList();
            
            return cities;
          }
        }
      }
    } catch (e) {
      print('Error searching cities by PIN code: $e');
    }
    
    return [];
  }
}
