import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/logger.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
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
    
    // --- ОСНОВНЕ ВИПРАВЛЕННЯ ТУТ ---
    final response = await supabase.auth.signUp(
      email: email, // Тепер ми впевнені, що вони не null
      password: password,
    );

    final user = response.user;
    if (user != null && response.session == null) {
      // Користувач створений, але потребує підтвердження
      return Response.json(body: {'status': 'needs_confirmation'});
    } else {
      // Це може спрацювати, якщо підтвердження email вимкнено
      return Response(
        statusCode: HttpStatus.badRequest,
        body: 'User might already exist or another issue occurred.',
      );
    }
  } on AuthException catch (e) {
    logger.severe('Supabase AuthException', e);
    return Response(statusCode: HttpStatus.badRequest, body: e.message);
  } catch (e, stackTrace) {
    logger.severe('Generic signUp ERROR', e, stackTrace);
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: 'An unexpected server error occurred.',
    );
  }
}