import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();

  if (context.request.method == HttpMethod.get) {
    return _get(context, supabase, user);
  }

  if (context.request.method == HttpMethod.post) {
    return _post(context, supabase, user);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Future<Response> _get(
  RequestContext context,
  SupabaseClient supabase,
  User user,
) async {
  final params = context.request.url.queryParameters;
  final walletId = int.tryParse(params['walletId'] ?? '');
  if (walletId == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'Wallet ID is required.',
    );
  }
  final isMember = await supabase.isUserMember(user.id, walletId);
  if (!isMember) return Response(statusCode: HttpStatus.forbidden);

  var query = supabase
      .from('transactions')
      .select('*, categories(*)')
      .eq('wallet_id', walletId);

  if (params['startDate'] != null) {
    query = query.gte('date', params['startDate']!);
  }
  if (params['endDate'] != null) {
    query = query.lte('date', params['endDate']!);
  }
  if (params['type'] != null) {
    query = query.eq('type', params['type']!);
  }
  if (params['categoryId'] != null) {
    query = query.eq('category_id', int.parse(params['categoryId']!));
  }
  if (params['q'] != null) {
    query = query.ilike('description', '%${params['q']}%');
  }

  final finalQuery = query.order('date', ascending: false);
  if (params['limit'] != null) {
    finalQuery.limit(int.parse(params['limit']!));
  }
  
  final response = await finalQuery;
  return Response.json(body: response);
}

Future<Response> _post(
  RequestContext context,
  SupabaseClient supabase,
  User user,
) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final walletId = body['wallet_id'] as int?;

  if (walletId == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: 'Wallet ID is required in body.',
    );
  }
  final canEdit = await supabase.canUserEdit(user.id, walletId);
  if (!canEdit) return Response(statusCode: HttpStatus.forbidden);

  final transactionData = {
    'user_id': user.id,
    'wallet_id': walletId,
    'type': body['type'],
    'original_amount': body['originalAmount'],
    'original_currency_code': body['originalCurrencyCode'],
    'amount_in_base_currency': body['amountInBaseCurrency'],
    'exchange_rate_used': body['exchangeRateUsed'],
    'category_id': body['categoryId'],
    'date': body['date'],
    'description': body['description'],
    'linked_goal_id': body['linkedGoalId'],
    'subscription_id': body['subscriptionId'],
    'linked_transfer_id': body['linkedTransferId'],
  };

  final response = await supabase
      .from('transactions')
      .insert(transactionData)
      .select()
      .single();

  return Response.json(statusCode: HttpStatus.created, body: response);
}