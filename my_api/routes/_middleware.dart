import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
// ІНТЕГРОВАНО: ховаємо зайвий HttpMethod з бібліотеки supabase
import 'package:supabase/supabase.dart' hide HttpMethod; 

Handler middleware(Handler handler) {
  return (RequestContext context) async {
    // Читаємо ключі з безпечних змінних оточення
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

    // Перевірка, чи змінні існують
    if (supabaseUrl == null || supabaseAnonKey == null) {
      // ІНТЕГРОВАНО: використовуємо stderr для логування помилок
      stderr.writeln(
        'CRITICAL ERROR: Supabase environment variables not found.',
      );
      return Response(
        statusCode: HttpStatus.internalServerError,
        body: 'Server configuration error',
      );
    }

    // Створюємо клієнт з отриманими даними
    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    var newContext = context.provide<SupabaseClient>(() => supabase);

    if (newContext.request.method == HttpMethod.options) {
      return Response(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        },
      );
    }

    if (newContext.request.url.path.startsWith('/auth/')) {
      final response = await handler(newContext);
      return response.copyWith(
        headers: {
          ...response.headers,
          'Access-Control-Allow-Origin': '*',
        },
      );
    }

    final authHeader = newContext.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(statusCode: 401, body: 'Unauthorized');
    }

    final token = authHeader.substring(7);
    final userResponse = await supabase.auth.getUser(token);

    if (userResponse.user == null) {
      return Response(statusCode: 401, body: 'Invalid Token');
    }

    newContext = newContext.provide<User>(() => userResponse.user!);

    final response = await handler(newContext);

    return response.copyWith(
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
      },
    );
  }.use(requestLogger());
}