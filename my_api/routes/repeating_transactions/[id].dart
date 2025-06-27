import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();
  final rtId = int.tryParse(id);

  if (rtId == null) return Response(statusCode: HttpStatus.badRequest);

  final data = await supabase
      .from('repeating_transactions')
      .select('wallet_id')
      .eq('id', rtId)
      .maybeSingle();
  if (data == null) return Response(statusCode: HttpStatus.notFound);

  final walletId = data['wallet_id'] as int;
  final canEdit = await supabase.canUserEdit(user.id, walletId);
  if (!canEdit) return Response(statusCode: HttpStatus.forbidden);

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;
    final response = await supabase
        .from('repeating_transactions')
        .update(body)
        .eq('id', rtId)
        .select()
        .single();
    return Response.json(body: response);
  }

  if (context.request.method == HttpMethod.delete) {
    await supabase.from('repeating_transactions').delete().eq('id', rtId);
    return Response(statusCode: HttpStatus.noContent);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}