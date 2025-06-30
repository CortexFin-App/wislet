import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final user = context.read<User>();

  return Response.json(
    body: {
      'id': user.id,
      'email': user.email,
      'name': user.userMetadata?['user_name'] ?? 'User',
    },
  );
}