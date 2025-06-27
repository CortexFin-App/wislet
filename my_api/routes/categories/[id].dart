import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();
  final categoryId = int.tryParse(id);

  if (categoryId == null) return Response(statusCode: HttpStatus.badRequest);

  final categoryData = await supabase.from('categories').select('wallet_id').eq('id', categoryId).maybeSingle();
  if (categoryData == null) return Response(statusCode: HttpStatus.notFound);
  
  final walletId = categoryData['wallet_id'] as int;
  final canEdit = await supabase.canUserEdit(user.id, walletId);
  if (!canEdit) return Response(statusCode: HttpStatus.forbidden);

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;
    final response = await supabase.from('categories').update(body).eq('id', categoryId).select().single();
    return Response.json(body: response);
  }

  if (context.request.method == HttpMethod.delete) {
    await supabase.from('categories').delete().eq('id', categoryId);
    return Response(statusCode: HttpStatus.noContent);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}