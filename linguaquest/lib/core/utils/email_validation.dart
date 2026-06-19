final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Mirrors the backend `isValidEmail`: requires `local@domain.tld` with no
/// whitespace. Rejects the garbled addresses that previously slipped through.
bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());
