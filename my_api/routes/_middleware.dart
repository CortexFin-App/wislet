import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../src/logger.dart';

SupabaseClient _initSupabase() {
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('CRITICAL: Supabase environment variables not found.');
  }
  return SupabaseClient(supabaseUrl, supabaseAnonKey);
}

final _supabaseClient = _initSupabase();

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      // КРОК 1: Спочатку НАДАЄМО SupabaseClient у контекст.
      .use(provider<SupabaseClient>((_) => _supabaseClient))
      // КРОК 2: І тільки потім застосовуємо middleware, який його ВИКОРИСТОВУЄ.
      .use(_authMiddleware());
}

Middleware _authMiddleware() {
  return (handler) {
    return (context) async {
      final path = context.request.url.path;

      if (path.startsWith('/auth/')) {
        return handler(context);
      }
      
      final supabase = context.read<SupabaseClient>();
      final authHeader = context.request.headers['Authorization'];

      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(statusCode: HttpStatus.unauthorized, body: 'Unauthorized');
      }

      final token = authHeader.substring(7);
      final userResponse = await supabase.auth.getUser(token);

      if (userResponse.user == null) {
        return Response(statusCode: HttpStatus.unauthorized, body: 'Invalid Token');
      }
      
      return handler(context.provide<User>(() => userResponse.user!));
    };
  };
}