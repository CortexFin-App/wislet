import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();
  final debtLoanId = int.tryParse(id);

  if (debtLoanId == null) return Response(statusCode: HttpStatus.badRequest);

  final data = await supabase
      .from('debts_loans')
      .select('wallet_id')
      .eq('id', debtLoanId)
      .maybeSingle();
  if (data == null) return Response(statusCode: HttpStatus.notFound);

  final walletId = data['wallet_id'] as int;
  final canEdit = await supabase.canUserEdit(user.id, walletId);
  if (!canEdit) return Response(statusCode: HttpStatus.forbidden);

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;
    final response = await supabase
        .from('debts_loans')
        .update(body)
        .eq('id', debtLoanId)
        .select()
        .single();
    return Response.json(body: response);
  }

  if (context.request.method == HttpMethod.delete) {
    await supabase.from('debts_loans').delete().eq('id', debtLoanId);
    return Response(statusCode: HttpStatus.noContent);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}