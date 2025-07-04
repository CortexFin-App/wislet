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
      body: 'Email and password are required',
    );
  }

  try {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null && response.session == null) {
      return Response.json(body: {'status': 'needs_confirmation'});
    } else {
      return Response(
        statusCode: HttpStatus.badRequest,
        body: 'User might already exist or another issue occurred.',
      );
    }
  } on AuthException catch (e, stackTrace) {
    // Грамотно обробляємо помилку автентифікації
    logger.severe('!!! Supabase AuthException !!!', e, stackTrace);
    return Response(statusCode: HttpStatus.badRequest, body: e.message);
  } catch (e, stackTrace) {
    // Грамотно обробляємо будь-яку іншу помилку
    logger.severe('!!! Generic signUp ERROR !!!', e, stackTrace);
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: 'An unexpected server error occurred.',
    );
  }
}