import 'dart:convert';

class PinCodeService {
  static const Map<String, Map<String, String>> _pinCodeData = {
    '110001': {
      'city': 'Delhi',
      'state': 'Delhi'
    },
    '110002': {
      'city': 'Mumbai',
      'state': 'Maharashtra'
    },
    '110003': {
      'city': 'Bangalore',
      'state': 'Karnataka'
    },
    '110004': {
      'city': 'Chennai',
      'state': 'Tamil Nadu'
    },
    '110005': {
      'city': 'Kolkata',
      'state': 'West Bengal'
    },
    '110006': {
      'city': 'Pune',
      'state': 'Maharashtra'
    },
    '110007': {
      'city': 'Jaipur',
      'state': 'Rajasthan'
    },
    '110008': {
      'city': 'Lucknow',
      'state': 'Uttar Pradesh'
    },
    '110009': {
      'city': 'Kanpur',
      'state': 'Uttar Pradesh'
    },
    '110010': {
      'city': 'Nagpur',
      'state': 'Maharashtra'
    },
  };
  
  static Map<String, String>? getPinCodeData(String pinCode) {
    if (pinCode.length == 6) {
      return _pinCodeData[pinCode];
    }
    return null;
  }
  
  static List<String> getAllPinCodes() {
    return _pinCodeData.keys.toList();
  }
}
