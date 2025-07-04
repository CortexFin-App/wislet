import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../src/logger.dart';

Handler middleware(Handler handler) {
  return (RequestContext context) async {
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      stderr.writeln('CRITICAL ERROR: Supabase environment variables not found.');
      return Response(
        statusCode: HttpStatus.internalServerError,
        body: 'Server configuration error',
      );
    }

    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    var newContext = context.provide<SupabaseClient>(() => supabase);

    logger.info('Incoming request to: ${newContext.request.uri.path}');

    if (newContext.request.url.path.startsWith('/auth/')) {
      return await handler(newContext);
    }

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