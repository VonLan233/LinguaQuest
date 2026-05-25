import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

String newSalt() => _uuid.v4();

String hashPassword(String password, String salt) {
  return sha256.convert(utf8.encode('$salt:$password')).toString();
}

String issueToken(
  AppConfig config, {
  required String uid,
  required String email,
}) {
  final jwt = JWT(
    {'uid': uid, 'email': email},
    issuer: 'linguaquest',
    subject: uid,
  );
  return jwt.sign(SecretKey(config.jwtSecret));
}

String? verifyToken(AppConfig config, String? authorizationHeader) {
  if (authorizationHeader == null ||
      !authorizationHeader.startsWith('Bearer ')) {
    return null;
  }
  final token = authorizationHeader.substring('Bearer '.length);
  try {
    final jwt = JWT.verify(token, SecretKey(config.jwtSecret));
    final payload = jwt.payload;
    if (payload is Map && payload['uid'] is String) {
      return payload['uid'] as String;
    }
  } on JWTException {
    return null;
  }
  return null;
}
