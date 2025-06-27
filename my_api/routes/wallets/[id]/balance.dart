import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();
  final walletId = int.tryParse(id);

  if (walletId == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  final isMember = await supabase.isUserMember(user.id, walletId);
  if (!isMember) {
    return Response(statusCode: HttpStatus.forbidden, body: 'Access Denied');
  }

  final incomeResponse = await supabase
      .from('transactions')
      .select('amount_in_base_currency')
      .eq('wallet_id', walletId)
      .eq('type', 'income');

  final expenseResponse = await supabase
      .from('transactions')
      .select('amount_in_base_currency')
      .eq('wallet_id', walletId)
      .eq('type', 'expense');

  final totalIncome = (incomeResponse as List)
      .fold<double>(0, (sum, item) => sum + (item['amount_in_base_currency'] as num));
  final totalExpense = (expenseResponse as List)
      .fold<double>(0, (sum, item) => sum + (item['amount_in_base_currency'] as num));

  return Response.json(body: {'balance': totalIncome - totalExpense});
}