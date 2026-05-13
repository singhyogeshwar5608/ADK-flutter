import 'dart:convert';
import 'package:http/http.dart' as http;

class PincodeApiServiceFixed {
  static const String _baseUrl = 'https://api.postalpincode.in/pincode';
  
  static Future<Map<String, String>?> getPincodeData(String pincode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$pincode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response Status: ${response.statusCode}');
        print('API Response Body: $data');
        
        if (data['Status'] == 'Success' && data['PostOffice'] != null) {
          final postOffices = data['PostOffice'] as List;
          if (postOffices.isNotEmpty) {
            final postOffice = postOffices[0];
            print('Post Office found: ${postOffice['Name']}');
            print('District: ${postOffice['District']}');
            print('State: ${postOffice['State']}');
            
            final Map<String, String> result = {
              'city': (postOffice['District'] ?? '').toString(),
              'state': (postOffice['State'] ?? '').toString(),
              'country': (postOffice['Country'] ?? 'India').toString(),
            };
            
            print('Returning result: $result');
            return result;
          } else {
            print('No Post Office found in response');
          }
        } else {
          print('API Status not Success: ${data['Status']}');
          print('PostOffice data: ${data['PostOffice']}');
        }
      } else {
        print('HTTP Error: Status ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching PIN code data: $e');
    }
    
    return null;
  }
  
  static Future<List<String>> searchCitiesByPincode(String pincode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$pincode'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
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
    } catch (e) {
      print('Error searching cities by PIN code: $e');
    }
    
    return [];
  }
}
