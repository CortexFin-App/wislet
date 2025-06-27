import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();
  final params = context.request.url.queryParameters;
  final walletId = int.tryParse(params['walletId'] ?? '');
  final startDate = params['startDate'];
  final endDate = params['endDate'];

  if (walletId == null || startDate == null || endDate == null) {
    return Response(
        statusCode: HttpStatus.badRequest, body: 'Missing required parameters');
  }

  final isMember = await supabase.isUserMember(user.id, walletId);
  if (!isMember) {
    return Response(statusCode: HttpStatus.forbidden, body: 'Access Denied');
  }

  final response = await supabase.rpc<dynamic>(
    'get_expenses_grouped_by_category',
    params: {
      'p_wallet_id': walletId,
      'p_start_date': startDate,
      'p_end_date': endDate,
    },
  );

  return Response.json(body: response);
}