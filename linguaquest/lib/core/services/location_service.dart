import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Returns the device's current position, or null when permission is denied
/// or location is otherwise unavailable. Never throws — callers treat null as
/// "skip silently".
Future<LatLng?> currentLatLng() async {
  try {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition();
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}
