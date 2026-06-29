import 'dart:math';

class StudySpotPolicy {
  static String? validate({
    required String name,
    required double latitude,
    required double longitude,
  }) {
    if (name.trim().isEmpty) return 'name_required';
    if (latitude < -90 || latitude > 90) return 'invalid_coordinates';
    if (longitude < -180 || longitude > 180) return 'invalid_coordinates';
    return null;
  }

  /// Great-circle distance in meters between two lat/lng points (haversine).
  static double distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = _radians(lat2 - lat1);
    final dLng = _radians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_radians(lat1)) *
            cos(_radians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _radians(double deg) => deg * pi / 180;

  /// Index of the nearest spot within [withinMeters] meters of
  /// ([latitude], [longitude]), or null if none qualify.
  static int? nearestWithin(
    List<({double latitude, double longitude})> spots,
    double latitude,
    double longitude, {
    double withinMeters = 100,
  }) {
    int? best;
    var bestDist = withinMeters;
    for (var i = 0; i < spots.length; i++) {
      final d = distanceMeters(
          latitude, longitude, spots[i].latitude, spots[i].longitude);
      if (d <= bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }
}
