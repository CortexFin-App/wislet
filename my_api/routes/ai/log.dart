import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final supabase = context.read<SupabaseClient>();
  final body = await context.request.json() as Map<String, dynamic>;
  final keyword = body['keyword'] as String?;
  final categoryName = body['category_name'] as String?;

  if (keyword == null || categoryName == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  await supabase.rpc<void>(
    'log_ai_suggestion',
    params: {
      'p_keyword': keyword,
      'p_category_name': categoryName,
    },
  );

  return Response(statusCode: HttpStatus.created);
}