import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import '../.dart_frog/server.dart' as server;
import '../src/logger.dart';

void main() async {
  setupLogger();
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => server.createServer(address, port));
}