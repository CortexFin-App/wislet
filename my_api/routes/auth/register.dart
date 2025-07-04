import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    return Response(
      statusCode: 500,
      body: 'FATAL: Supabase environment variables are not set!',
    );
  }

  // ----- ОСЬ ФІНАЛЬНЕ ВИПРАВЛЕННЯ -----
  // Ми додаємо '!', щоб запевнити компілятор, що ми вже перевірили ці змінні
  final supabase = SupabaseClient(supabaseUrl!, supabaseAnonKey!);
  // -------------------------

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response(statusCode: 400, body: 'Email and password required.');
    }

    await supabase.auth.signUp(email: email, password: password);
    
    return Response(body: 'Success! Please check your email for confirmation.');
  } on AuthException catch (e) {
    return Response(statusCode: 400, body: 'AuthException: ${e.message}');
  } catch (e) {
    return Response(statusCode: 500, body: 'Generic Error: ${e.toString()}');
  }
}