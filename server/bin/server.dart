import 'dart:io';

import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/database.dart';
import 'package:linguaquest_server/src/routes.dart';
import 'package:linguaquest_server/src/wordbook_service.dart';
import 'package:path/path.dart' as p;

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final config = AppConfig.fromEnvironment();
  final database = await AppDatabase.connect(config);
  await database.migrate();

  final wordbookService = WordBookService();
  final wordbooksPath = p.join(Directory.current.path, 'data', 'wordbooks');
  await wordbookService.loadFromDirectory(wordbooksPath);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addHandler(buildRouter(config, database, wordbookService).call);

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.port,
  );

  stdout.writeln(
    'LinguaQuest server listening on http://${server.address.host}:${server.port}',
  );
}
