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
        statusCode: HttpStatus.badRequest, body: 'Email and password are required');
  }

  try {
    final response = await supabase.auth.signUp(email: email, password: password);
    final session = response.session;
    if (session != null) {
      return Response.json(
        body: {
          'access_token': session.accessToken,
          'refresh_token': session.refreshToken,
          'user_id': session.user.id,
          'user_name': response.user?.userMetadata?['user_name'] ?? 'User',
        },
      );
    } else {
      logger.warning('Registration attempt failed, but no exception was thrown. User might already exist or signups are disabled.');
      return Response(
        statusCode: HttpStatus.unauthorized,
        body: 'Registration failed. Please check if signups are enabled in Supabase settings.',
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