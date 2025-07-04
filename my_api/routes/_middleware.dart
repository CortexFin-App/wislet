import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../src/logger.dart';

Handler middleware(Handler handler) {
  return (context) {
    // Надаємо Supabase клієнт у контекст
    return handler.use(
      provider<SupabaseClient>(
        (_) {
          final supabaseUrl = Platform.environment['SUPABASE_URL']!;
          final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY']!;
          return SupabaseClient(supabaseUrl, supabaseAnonKey);
        },
      ),
    );
  }
  .use(requestLogger())
  .use(_authMiddleware());
}

Middleware _authMiddleware() {
  return (handler) {
    return (context) async {
      // Клієнт вже надано попереднім middleware.
      final supabase = context.read<SupabaseClient>();
      final path = context.request.url.path;

      // Публічні роути
      if (path.startsWith('/auth/')) {
        return handler(context);
      }

      // Захищені роути
      final authHeader = context.request.headers['Authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(statusCode: HttpStatus.unauthorized, body: 'Unauthorized');
      }

      final token = authHeader.substring(7);
      final userResponse = await supabase.auth.getUser(token);
      if (userResponse.user == null) {
        return Response(statusCode: HttpStatus.unauthorized, body: 'Invalid Token');
      }

      final userContext = context.provide<User>(() => userResponse.user!);
      return handler(userContext);
    };
  };
}