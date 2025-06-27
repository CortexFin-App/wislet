import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();
  final budgetId = int.tryParse(id);

  if (budgetId == null) return Response(statusCode: HttpStatus.badRequest);

  final budgetData = await supabase
      .from('budgets')
      .select('wallet_id')
      .eq('id', budgetId)
      .maybeSingle();

  if (budgetData == null) {
    return Response(statusCode: HttpStatus.notFound);
  }

  final walletId = budgetData['wallet_id'] as int;
  final isMember = await supabase.isUserMember(user.id, walletId);
  if (!isMember) return Response(statusCode: HttpStatus.forbidden);

  if (context.request.method == HttpMethod.get) {
    final response =
        await supabase.from('budgets').select().eq('id', budgetId).single();
    return Response.json(body: response);
  }

  final canEdit = await supabase.canUserEdit(user.id, walletId);
  if (!canEdit) return Response(statusCode: HttpStatus.forbidden);

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;
    final response = await supabase
        .from('budgets')
        .update(body)
        .eq('id', budgetId)
        .select()
        .single();
    return Response.json(body: response);
  }

  if (context.request.method == HttpMethod.delete) {
    await supabase.from('budgets').delete().eq('id', budgetId);
    return Response(statusCode: HttpStatus.noContent);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}