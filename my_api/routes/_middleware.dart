import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Handler middleware(Handler handler) {
  return (context) async {
    // 1. Ініціалізуємо Supabase для КОЖНОГО запиту. Це не оптимально, але на 100% надійно для діагностики.
    final supabaseUrl = Platform.environment['SUPABASE_URL'];
    final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseAnonKey == null) {
      return Response(statusCode: 500, body: 'Server Not Configured');
    }
    final supabase = SupabaseClient(supabaseUrl, supabaseAnonKey);
    var newContext = context.provide<SupabaseClient>(() => supabase);

    // 2. Якщо це публічний роут - одразу передаємо керування далі
    final path = newContext.request.url.path;
    if (path.startsWith('/auth/')) {
      return handler(newContext);
    }

    // --- З ЦЬОГО МОМЕНТУ ВСІ РОУТИ ВВАЖАЮТЬСЯ ЗАХИЩЕНИМИ ---
    final authHeader = newContext.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(statusCode: 401, body: 'Unauthorized: No token');
    }

    final token = authHeader.substring(7);
    final userResponse = await supabase.auth.getUser(token);
    if (userResponse.user == null) {
      return Response(statusCode: 401, body: 'Unauthorized: Invalid token');
    }

    // 3. Надаємо користувача в контекст і передаємо керування далі
    newContext = newContext.provide<User>(() => userResponse.user!);
    return handler(newContext);
  };
}