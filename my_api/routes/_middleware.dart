import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../src/logger.dart';

Handler middleware(Handler handler) {
  // Повертаємо єдиний, правильно типізований обробник
  return (RequestContext context) async {
    
    // --- 1. Ініціалізація Supabase ---
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      logger.severe('CRITICAL: Supabase environment variables not found.');
      return Response(
        statusCode: HttpStatus.internalServerError,
        body: 'Server configuration error',
      );
    }
    
    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);

    // --- 2. Надання залежностей і обробка CORS ---
    var newContext = context.provide<SupabaseClient>(() => supabase);

    if (newContext.request.method == HttpMethod.options) {
      return Response(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
      });
    }

    // --- 3. Основна логіка ---
    final response = await _handleAuth(newContext, handler);

    // --- 4. Додаємо CORS до всіх успішних відповідей ---
    return response.copyWith(
      headers: {
        ...response.headers,
        'Access-Control-Allow-Origin': '*',
      },
    );
  }.use(requestLogger());
}

// Допоміжна функція для логіки авторизації
Future<Response> _handleAuth(RequestContext context, Handler handler) async {
  final path = context.request.url.path;
  final supabase = context.read<SupabaseClient>();
  
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

  // Надаємо об'єкт User і передаємо запит далі
  final userContext = context.provide<User>(() => userResponse.user!);
  return handler(userContext);
}