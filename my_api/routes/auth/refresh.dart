import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;
  final refreshToken = body['refresh_token'] as String?;

  if (refreshToken == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Refresh token is required');
  }

  try {
    final response = await supabase.auth.refreshSession(refreshToken);
    final session = response.session;

    if (session != null) {
      return Response.json(body: {
        'access_token': session.accessToken,
        'refresh_token': session.refreshToken,
      });
    } else {
      return Response(statusCode: HttpStatus.unauthorized, body: 'Invalid refresh token');
    }
  } catch (e) {
    return Response(statusCode: HttpStatus.internalServerError, body: e.toString());
  }
}