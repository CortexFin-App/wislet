import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();
  final body = await context.request.json() as Map<String, dynamic>;

  final fromWalletId = body['from_wallet_id'] as int?;
  final toWalletId = body['to_wallet_id'] as int?;
  final amount = body['amount'] as num?;

  if (fromWalletId == null || toWalletId == null || amount == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  final canEditFrom = await supabase.canUserEdit(user.id, fromWalletId);
  final canEditTo = await supabase.canUserEdit(user.id, toWalletId);

  if (!canEditFrom || !canEditTo) {
    return Response(statusCode: HttpStatus.forbidden);
  }

  await supabase.rpc<void>(
    'create_transfer',
    params: {
      'p_from_wallet_id': fromWalletId,
      'p_to_wallet_id': toWalletId,
      'p_amount': amount,
      'p_user_id': user.id,
      'p_currency_code': body['currency_code'],
      'p_description': body['description'],
      'p_date': body['date'],
    },
  );

  return Response(statusCode: HttpStatus.created);
}