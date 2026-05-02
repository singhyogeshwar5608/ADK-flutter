import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static Future<String> getAuthToken() async {
    // Try multiple token sources
    final prefs = await SharedPreferences.getInstance();
    final token1 = prefs.getString('auth_token') ?? '';
    final token2 = prefs.getString('access_token') ?? '';
    final token3 = prefs.getString('netshop_access_token') ?? '';
    final token4 = prefs.getString('token') ?? '';
    
    final token = token1.isNotEmpty ? token1 : 
                  token2.isNotEmpty ? token2 : 
                  token3.isNotEmpty ? token3 : token4;

    print('Flutter Auth Debug:');
    print('- auth_token: $token1');
    print('- access_token: $token2');
    print('- netshop_access_token: $token3');
    print('- token: $token4');
    print('- Using token: $token');

    // Return hardcoded token for testing if no token found
    if (token.isEmpty) {
      print('No token found, using hardcoded token for testing');
      return '232|4CpUCY88oK1ZU83LB5f4Iv2qHTZLFnUQAMbGxDGx89a49d10';
    }
    
    return token;
  }
}
