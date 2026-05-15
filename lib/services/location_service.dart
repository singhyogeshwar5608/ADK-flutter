import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UserLocation {
  final String country;
  final String state;
  final bool isFallback;

  const UserLocation({
    required this.country,
    required this.state,
    this.isFallback = false,
  });

  factory UserLocation.india() => const UserLocation(country: 'India', state: 'Haryana');
}

class LocationService {
  static const String _ipApiUrl = 'http://ip-api.com/json/';

  Future<UserLocation> detectLocation() async {
    try {
      // 1. Try Browser/Device Geolocation first
      if (!kIsWeb || await _checkPermissions()) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
        
        // Note: Reverse geocoding usually requires a paid API like Google Maps.
        // For this implementation, we will use IP-based detection as primary/fallback 
        // because it directly provides Country/State names which we need for GST.
        return await _detectViaIP();
      }
    } catch (e) {
      debugPrint('Geolocation error: $e');
    }
    
    // 2. Fallback to IP-based detection
    return await _detectViaIP();
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<UserLocation> _detectViaIP() async {
    try {
      final response = await http.get(Uri.parse(_ipApiUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserLocation(
          country: (data['country'] as String? ?? 'India').trim(),
          state: (data['regionName'] as String? ?? 'Haryana').trim(),
          isFallback: true,
        );
      }
    } catch (e) {
      debugPrint('IP Location error: $e');
    }
    return UserLocation.india(); // Ultimate fallback
  }
}
