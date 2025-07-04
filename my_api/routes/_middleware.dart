import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../src/logger.dart';

Handler middleware(Handler handler) {
  return (RequestContext context) async {
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      return Response(statusCode: HttpStatus.internalServerError);
    }
    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    var newContext = context.provide<SupabaseClient>(() => supabase);

    final path = newContext.request.url.path;

    // ================== НАШ ГОЛОВНИЙ ДЕБАГ ==================
    print('--- DEBUG: Received request for path: "$path" ---');
    // =======================================================

    if (path.startsWith('/auth/')) {
      print('--- DEBUG: Path matches /auth/. Bypassing auth check. ---');
      return handler(newContext);
    }
    
    print('--- DEBUG: Path does NOT match /auth/. Applying auth check. ---');
    final authHeader = newContext.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(statusCode: HttpStatus.unauthorized, body: 'Unauthorized');
    }

    final token = authHeader.substring(7);
    final userResponse = await supabase.auth.getUser(token);
    if (userResponse.user == null) {
      return Response(statusCode: HttpStatus.unauthorized, body: 'Invalid Token');
    }
    
    newContext = newContext.provide<User>(() => userResponse.user!);
    return handler(newContext);

  }.use(requestLogger());
}