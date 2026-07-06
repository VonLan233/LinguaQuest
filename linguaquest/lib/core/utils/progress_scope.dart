/// Composite scope token for progress isolation.
///
/// Format: `"<language>::<wordBookId>"`  e.g. `"zh::hsk1"`, `"ja::jlpt_n5"`.
/// This is the ONLY place the separator is defined.
String progressScope(String language, String wordBookId) =>
    '$language::$wordBookId';
