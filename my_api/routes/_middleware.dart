import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

// Ця функція створює екземпляр Supabase. Вона буде викликана один раз.
SupabaseClient _initSupabase() {
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    // Це фатальна помилка, без ключів сервер не може працювати.
    throw Exception('CRITICAL: Supabase environment variables not found.');
  }
  return SupabaseClient(supabaseUrl, supabaseAnonKey);
}

// Створюємо єдиний екземпляр клієнта при старті
final _supabaseClient = _initSupabase();

Handler middleware(Handler handler) {
  // Послідовно застосовуємо наші middleware до основного обробника
  return handler
      .use(requestLogger())
      // Надаємо єдиний екземпляр Supabase кожному запиту
      .use(provider<SupabaseClient>((_) => _supabaseClient))
      // Застосовуємо наш middleware для автентифікації
      .use(_authMiddleware());
}

// Наш кастомний middleware для перевірки токенів
Middleware _authMiddleware() {
  return (handler) {
    return (context) async {
      final path = context.request.url.path;

      // Публічні роути не потребують перевірки
      if (path.startsWith('/auth/')) {
        return handler(context);
      }

      // Для всіх інших роутів перевіряємо токен
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
      
      // Надаємо об'єкт User для захищених роутів
      return handler(context.provide<User>(() => userResponse.user!));
    };
  };
}