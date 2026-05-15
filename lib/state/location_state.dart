import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationState extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  
  UserLocation? _currentLocation;
  bool _isLoading = false;
  String? _error;

  UserLocation? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  LocationState() {
    detectUserLocation();
  }

  Future<void> detectUserLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentLocation = await _locationService.detectLocation();
    } catch (e) {
      _error = e.toString();
      _currentLocation = UserLocation.india(); // Fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateLocation(String country, String state) {
    _currentLocation = UserLocation(country: country, state: state);
    notifyListeners();
  }
}

class LocationProvider extends InheritedNotifier<LocationState> {
  const LocationProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static LocationState of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<LocationProvider>();
    assert(provider != null, 'No LocationProvider found in context');
    return provider!.notifier!;
  }
}
