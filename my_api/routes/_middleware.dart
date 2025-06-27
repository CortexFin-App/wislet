import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Handler middleware(Handler handler) {
  return (RequestContext context) async {
    final supabase = SupabaseClient('https://xdofjorgomwdyawmwbcj.supabase.co', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhkb2Zqb3Jnb213ZHlhd213YmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMzE0MTcsImV4cCI6MjA2NDkwNzQxN30.2i9ru8fXLZEYD_jNHoHd0ZJmN4k9gKcPOChdiuL_AMY');
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