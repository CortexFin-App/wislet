import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/logger.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;
  final email = body['email'] as String?;
  final password = body['password'] as String?;

  if (email == null || password == null) {
    return Response(
        statusCode: HttpStatus.badRequest,
        body: 'Email and password are required');
  }

  try {
    final response = await supabase.auth.signUp(email: email, password: password);
    final session = response.session;
    final user = response.user;

    if (session != null) {
      return Response.json(
        body: {
          'status': 'session_created',
          'access_token': session.accessToken,
          'refresh_token': session.refreshToken,
          'user_id': session.user.id,
          'user_name': user?.userMetadata?['user_name'] ?? 'User',
        },
      );
    } 
    else if (user != null && user.aud == 'authenticated') {
      return Response.json(body: {'status': 'needs_confirmation'});
    } 
    else {
      logger.warning('Registration attempt failed: ${response.toString()}');
      return Response(
        statusCode: HttpStatus.badRequest,
        body: 'User might already exist or another issue occurred.',
      );
    }
  } catch (e, stackTrace) {
    logger.severe('!!! Supabase signUp ERROR !!!', e, stackTrace);
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: 'Supabase Error: ${e.toString()}',
    );
  }
}