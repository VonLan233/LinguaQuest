import 'dart:convert';

import 'package:shelf/shelf.dart';

const jsonHeaders = {'Content-Type': 'application/json; charset=utf-8'};

Response jsonResponse(Object body, {int status = 200}) {
  return Response(status, body: jsonEncode(body), headers: jsonHeaders);
}

Future<Map<String, dynamic>> readJsonMap(Request request) async {
  final raw = await request.readAsString();
  if (raw.trim().isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Expected a JSON object');
  }
  return Map<String, dynamic>.from(decoded);
}
