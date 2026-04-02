import 'package:geolocator/geolocator.dart';

/// Thin wrapper around the Geolocator plugin.
class LocationService {
  LocationService._();
  static final instance = LocationService._();

  /// Checks and requests location permission.
  /// Returns `true` if permission is granted.
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Returns the current GPS position.
  /// Throws if permission is not granted.
  Future<Position> getCurrentPosition() async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }
}
