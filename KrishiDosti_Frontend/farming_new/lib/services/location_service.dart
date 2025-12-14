// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

class LocationInfo {
  final double latitude;
  final double longitude;
  final String area; // neighbourhood / village
  final String city;
  final String state;
  final String country;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.city,
    required this.state,
    required this.country,
  });
}

class LocationService {
  Future<LocationInfo> getLocationInfo() async {
    // 1️⃣ Check service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location service is disabled');
    }

    // 2️⃣ Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    // 3️⃣ Get GPS
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4️⃣ Reverse geocode
    final placemarks = await geocoding.placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final place = placemarks.isNotEmpty ? placemarks.first : null;

    return LocationInfo(
      latitude: position.latitude,
      longitude: position.longitude,
      area: place?.subLocality ?? '',
      city: place?.locality ?? place?.subAdministrativeArea ?? '',
      state: place?.administrativeArea ?? '',
      country: place?.country ?? '',
    );
  }
}
