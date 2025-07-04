import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  print('--- [1] Handler started ---');
  
  if (context.request.method != HttpMethod.post) {
    print('--- [E] ERROR: Method not POST ---');
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  print('--- [2] Reading environment variables ---');
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

  print('--- [3] URL is: ${supabaseUrl ?? "NULL"} ---');
  print('--- [4] ANON_KEY is: ${supabaseAnonKey ?? "NULL"} ---');

  if (supabaseUrl == null || supabaseAnonKey == null) {
    print('--- [E] FATAL: Env vars missing! ---');
    return Response(statusCode: 500, body: 'FATAL: Supabase env vars not set!');
  }
  
  print('--- [5] Initializing SupabaseClient ---');
  final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
  print('--- [6] SupabaseClient initialized ---');
  
  try {
    print('--- [7] TRY block started ---');
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email'] as String?;
    final password = body['password'] as String?;
    print('--- [8] Email: $email, Password: [REDACTED] ---');
    
    if (email == null || password == null) {
      print('--- [E] Email or password is null ---');
      return Response(statusCode: 400, body: 'Email/password required.');
    }

    print('--- [9] Calling supabase.auth.signUp ---');
    await supabase.auth.signUp(email: email, password: password);
    print('--- [10] SUCCESS: signUp call finished ---');
    
    return Response(body: 'Success! Check your email!');
  } on AuthException catch (e) {
    print('--- [E] CATCH AuthException: ${e.message} ---');
    return Response(statusCode: 400, body: e.message);
  } catch (e) {
    print('--- [E] CATCH Generic Error: ${e.toString()} ---');
    return Response(statusCode: 500, body: 'Generic Error');
  }
}