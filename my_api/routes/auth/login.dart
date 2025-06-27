import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;
  final email = body['email'] as String?;
  final password = body['password'] as String?;

  if (email == null || password == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Email and password are required');
  }

  try {
    final response = await supabase.auth.signInWithPassword(email: email, password: password);
    final session = response.session;
    
    if (session != null) {
      return Response.json(body: {
        'token': session.accessToken,
        'user_id': session.user.id,
      },);
    } else {
      return Response(statusCode: HttpStatus.unauthorized, body: 'Invalid credentials');
    }
  } catch (e) {
    return Response(statusCode: HttpStatus.internalServerError, body: e.toString());
  }
}