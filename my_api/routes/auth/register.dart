import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/logger.dart'; // Припускаємо, що src/logger.dart існує

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      return Response(statusCode: 500, body: 'Server Not Configured');
    }

    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response(statusCode: 400, body: 'Email and password required.');
    }

    await supabase.auth.signUp(email: email, password: password);
    
    return Response(body: 'Success!');

  } on AuthException catch (e, stackTrace) {
    logger.severe('!!! Supabase AuthException !!!', e, stackTrace);
    return Response(statusCode: HttpStatus.badRequest, body: e.message);
  } catch (e, stackTrace) {
    // Цей блок тепер запише АБСОЛЮТНО ВСЕ про помилку
    logger.severe('!!! Generic Unhandled Exception !!!', e, stackTrace);
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: 'An unexpected server error occurred. Check server logs for details.',
    );
  }
}