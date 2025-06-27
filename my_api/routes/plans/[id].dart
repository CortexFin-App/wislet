import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();
  final planId = int.tryParse(id);

  if (planId == null) return Response(statusCode: HttpStatus.badRequest);

  final planData = await supabase.from('plans').select('wallet_id').eq('id', planId).maybeSingle();
  if (planData == null) return Response(statusCode: HttpStatus.notFound);
  
  final walletId = planData['wallet_id'] as int;
  final canEdit = await supabase.canUserEdit(user.id, walletId);
  if (!canEdit) return Response(statusCode: HttpStatus.forbidden);

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;
    final response = await supabase.from('plans').update(body).eq('id', planId).select().single();
    return Response.json(body: response);
  }

  if (context.request.method == HttpMethod.delete) {
    await supabase.from('plans').delete().eq('id', planId);
    return Response(statusCode: HttpStatus.noContent);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}