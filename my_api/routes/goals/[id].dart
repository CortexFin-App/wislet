import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();
  final goalId = int.tryParse(id);

  if (goalId == null) return Response(statusCode: HttpStatus.badRequest);

  final goalData = await supabase
      .from('financial_goals')
      .select('wallet_id')
      .eq('id', goalId)
      .maybeSingle();
      
  if (goalData == null) return Response(statusCode: HttpStatus.notFound);

  final walletId = goalData['wallet_id'] as int;
  final canEdit = await supabase.canUserEdit(user.id, walletId);
  if (!canEdit) return Response(statusCode: HttpStatus.forbidden);

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;
    final response = await supabase
        .from('financial_goals')
        .update(body)
        .eq('id', goalId)
        .select()
        .single();
    return Response.json(body: response);
  }

  if (context.request.method == HttpMethod.delete) {
    await supabase.from('financial_goals').delete().eq('id', goalId);
    return Response(statusCode: HttpStatus.noContent);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}