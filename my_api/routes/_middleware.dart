import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Handler middleware(Handler handler) {
  return (context) async {
    // Кожен запит буде проходити через цей код послідовно.

    // 1. Ініціалізуємо Supabase
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      return Response(statusCode: 500, body: 'Server config error');
    }
    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

    // 2. Надаємо клієнт в контекст
    var newContext = context.provide<SupabaseClient>(() => supabase);

    // 3. Перевіряємо шлях
    final path = newContext.request.url.path;

    if (path.startsWith('/auth/')) {
      // Якщо це публічний роут, одразу передаємо керування далі
      return handler(newContext);
    }

    // --- З ЦЬОГО МОМЕНТУ ВСІ РОУТИ ВВАЖАЮТЬСЯ ЗАХИЩЕНИМИ ---

    // 4. Перевіряємо заголовок авторизації
    final authHeader = newContext.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(statusCode: 401, body: 'Unauthorized: No token');
    }

    // 5. Валідуємо токен
    final token = authHeader.substring(7);
    final userResponse = await supabase.auth.getUser(token);
    if (userResponse.user == null) {
      return Response(statusCode: 401, body: 'Unauthorized: Invalid token');
    }

    // 6. Надаємо користувача в контекст і передаємо керування далі
    newContext = newContext.provide<User>(() => userResponse.user!);
    return handler(newContext);
  };
}