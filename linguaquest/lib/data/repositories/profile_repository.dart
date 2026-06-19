abstract class ProfileRepository {
  /// Fetches the privacy-filtered public profile for [userId].
  ///
  /// The returned map contains at minimum `uid` and `name`.
  /// Optional keys are present only when the viewed user's privacy settings
  /// allow them:
  ///   - `isOwner` (bool)
  ///   - `streak` (int)
  ///   - `stats` (Map of String to dynamic)
  ///   - `achievements` (List)
  ///   - `posts` (List)
  ///   - `wordbookProgress` (int)
  Future<Map<String, dynamic>> getPublicProfile(String userId);
}
