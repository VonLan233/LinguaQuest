import 'dart:convert';

void main() {
  final content = jsonEncode({
    'mainClause': 'The fox jumps',
    'clauses': <String>[],
    'modifiers': ['quick', 'brown'],
    'translation': '狐狸跳',
    'vocabularyNotes': <String>[],
  });
  
  final body = jsonEncode({
    'choices': [
      {'message': {'content': content}},
    ],
  });
  
  print('Content: $content');
  print('Body: $body');
  
  // Simulate what RemoteAiProvider does
  try {
    final outer = jsonDecode(body) as Map<String, dynamic>;
    final choices = outer['choices'] as List;
    print('Choices length: ${choices.length}');
    print('First choice: ${choices.first}');
    final msg = (choices.first as Map)['message'];
    print('Message: $msg');
    final msgContent = msg['content'] as String;
    print('Message content: $msgContent');
    final data = jsonDecode(msgContent) as Map<String, dynamic>;
    print('Parsed data: $data');
    print('SUCCESS: ${data['mainClause']}');
  } catch (e, st) {
    print('ERROR: $e');
    print(st);
  }
}
