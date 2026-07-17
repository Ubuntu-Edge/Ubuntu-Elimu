import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/enhanced_message.dart';

/// Service for handling location sharing in messages
/// Provides current location and address lookup functionality
class LocationSharingService {
  static final LocationSharingService _instance = LocationSharingService._internal();
  factory LocationSharingService() => _instance;
  LocationSharingService._internal();

  // Stream controller for location updates
  final _locationController = StreamController<LocationData>.broadcast();
  Stream<LocationData> get locationStream => _locationController.stream;

  bool _isTrackingLocation = false;
  Timer? _locationTimer;

  /// Check if location permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    // In production, use geolocator:
    // return await Geolocator.isLocationServiceEnabled();
    return true; // Placeholder
  }

  /// Get current location
  Future<LocationData?> getCurrentLocation() async {
    // Check permission
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('Location permission denied');
        return null;
      }
    }

    // Check if location services are enabled
    if (!await isLocationServiceEnabled()) {
      debugPrint('Location services are disabled');
      return null;
    }

    try {
      // In production, use geolocator:
      // final position = await Geolocator.getCurrentPosition(
      //   desiredAccuracy: LocationAccuracy.high,
      // );
      // 
      // return LocationData(
      //   latitude: position.latitude,
      //   longitude: position.longitude,
      //   accuracy: position.accuracy,
      // );

      // For now, return a placeholder location in Nairobi, Kenya
      final location = LocationData(
        latitude: -1.2921,
        longitude: 36.8219,
        accuracy: 10.0,
        address: 'Nairobi, Kenya',
        placeName: 'Kenyatta International Convention Centre',
      );

      debugPrint('Got location: ${location.latitude}, ${location.longitude}');
      return location;
    } catch (e) {
      debugPrint('Failed to get location: $e');
      return null;
    }
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // In production, use geocoding package:
      // List<Placemark> placemarks = await placemarkFromCoordinates(
      //   latitude,
      //   longitude,
      // );
      // 
      // if (placemarks.isNotEmpty) {
      //   final place = placemarks.first;
      //   return '${place.street}, ${place.locality}, ${place.country}';
      // }

      // Placeholder address based on coordinates
      if (latitude >= -1.5 && latitude <= -1.0 &&
          longitude >= 36.5 && longitude <= 37.0) {
        return 'Nairobi, Kenya';
      }
      
      return 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      debugPrint('Failed to get address: $e');
      return null;
    }
  }

  /// Get coordinates from address (forward geocoding)
  Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      // In production, use geocoding package:
      // List<Location> locations = await locationFromAddress(address);
      // 
      // if (locations.isNotEmpty) {
      //   return LocationData(
      //     latitude: locations.first.latitude,
      //     longitude: locations.first.longitude,
      //     address: address,
      //   );
      // }

      // Placeholder - return Nairobi coordinates for any search
      return LocationData(
        latitude: -1.2921,
        longitude: 36.8219,
        address: address,
      );
    } catch (e) {
      debugPrint('Failed to get coordinates: $e');
      return null;
    }
  }

  /// Start tracking location for real-time updates
  Future<bool> startLocationTracking({Duration interval = const Duration(seconds: 30)}) async {
    if (_isTrackingLocation) {
      debugPrint('Already tracking location');
      return true;
    }

    // Check permission
    if (!await hasPermission()) {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('Location permission denied');
        return false;
      }
    }

    _isTrackingLocation = true;

    // In production, use geolocator stream:
    // _positionStreamSubscription = Geolocator.getPositionStream(
    //   locationSettings: LocationSettings(
    //     accuracy: LocationAccuracy.high,
    //     distanceFilter: 10,
    //   ),
    // ).listen((Position position) {
    //   final location = LocationData(
    //     latitude: position.latitude,
    //     longitude: position.longitude,
    //     accuracy: position.accuracy,
    //   );
    //   _locationController.add(location);
    // });

    // Simulate location updates with a timer
    _locationTimer = Timer.periodic(interval, (_) async {
      final location = await getCurrentLocation();
      if (location != null) {
        _locationController.add(location);
      }
    });

    debugPrint('Started location tracking');
    return true;
  }

  /// Stop tracking location
  void stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTrackingLocation = false;
    debugPrint('Stopped location tracking');
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Haversine formula
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2));
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }

  /// Format distance for display
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toInt()} m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.toInt()} km';
    }
  }

  /// Get a static map URL for preview
  String getStaticMapUrl(double latitude, double longitude, {int zoom = 15, int width = 300, int height = 200}) {
    // Using OpenStreetMap static tiles (in production, use a proper map API)
    // This is a placeholder URL format
    return 'https://staticmap.openstreetmap.de/staticmap.php?'
        'center=$latitude,$longitude'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&markers=$latitude,$longitude,red-pushpin';
  }

  /// Get a maps app URL to open in external app
  String getMapsUrl(double latitude, double longitude, {String? label}) {
    final encodedLabel = label != null ? Uri.encodeComponent(label) : '';
    
    // Universal Google Maps URL that works on both platforms
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude${encodedLabel.isNotEmpty ? '&query_place_id=$encodedLabel' : ''}';
  }

  /// Get saved/favorite locations
  Future<List<SavedLocation>> getSavedLocations() async {
    // In production, load from database
    return [
      SavedLocation(
        id: '1',
        name: 'Health Center',
        location: LocationData(
          latitude: -1.2900,
          longitude: 36.8200,
          placeName: 'Kenyatta National Hospital',
          address: 'Hospital Road, Nairobi',
        ),
      ),
      SavedLocation(
        id: '2',
        name: 'Office',
        location: LocationData(
          latitude: -1.2950,
          longitude: 36.8180,
          placeName: 'Ministry of Health',
          address: 'Afya House, Cathedral Road',
        ),
      ),
    ];
  }

  /// Save a location as favorite
  Future<void> saveLocation(SavedLocation location) async {
    // In production, save to database
    debugPrint('Saved location: ${location.name}');
  }

  /// Delete a saved location
  Future<void> deleteSavedLocation(String id) async {
    // In production, delete from database
    debugPrint('Deleted saved location: $id');
  }

  /// Dispose resources
  void dispose() {
    _locationTimer?.cancel();
    _locationController.close();
  }
}

/// Saved/favorite location
class SavedLocation {
  final String id;
  final String name;
  final LocationData location;
  final DateTime? createdAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.location,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location.toMap(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'],
      name: map['name'],
      location: LocationData.fromMap(map['location']),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
    );
  }
}

// Math helpers - these should ideally come from dart:math
double sin(double x) => _sin(x);
double cos(double x) => _cos(x);
double sqrt(double x) => _sqrt(x);
double atan2(double y, double x) => _atan2(y, x);

// Simple approximations (in production, use dart:math)
double _sin(double x) {
  // Normalize to -pi to pi
  x = x % (2 * 3.14159265359);
  if (x > 3.14159265359) x -= 2 * 3.14159265359;
  if (x < -3.14159265359) x += 2 * 3.14159265359;
  
  // Taylor series approximation
  double result = x;
  double term = x;
  for (int i = 1; i < 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }
  return result;
}

double _cos(double x) {
  return _sin(x + 3.14159265359 / 2);
}

double _sqrt(double x) {
  if (x <= 0) return 0;
  double guess = x / 2;
  for (int i = 0; i < 10; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}

double _atan2(double y, double x) {
  if (x > 0) return _atan(y / x);
  if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
  if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
  if (y > 0) return 3.14159265359 / 2;
  if (y < 0) return -3.14159265359 / 2;
  return 0;
}

double _atan(double x) {
  // Simple atan approximation
  if (x.abs() > 1) {
    return (3.14159265359 / 2) - _atan(1 / x);
  }
  double result = x;
  double term = x;
  for (int i = 1; i < 10; i++) {
    term *= -x * x;
    result += term / (2 * i + 1);
  }
  return result;
}
