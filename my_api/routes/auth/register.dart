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
    await supabase.auth.signUp(email: email, password: password);
    return Response(body: 'Success! Please check your email to confirm your account.');
  } on AuthException catch (e) {
    return Response(statusCode: HttpStatus.badRequest, body: e.message);
  } catch (e) {
    return Response(statusCode: 500, body: 'An unexpected error occurred: ${e.toString()}');
  }
}