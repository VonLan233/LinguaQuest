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
}
