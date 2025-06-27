import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();

  if (context.request.method == HttpMethod.get) {
    final userWallets = await supabase
        .from('wallet_users')
        .select('wallet_id')
        .eq('user_id', user.id);

    final walletIds = userWallets.map((e) => e['wallet_id'] as int).toList();

    if (walletIds.isEmpty) {
      return Response.json(body: []);
    }

    final response = await supabase
        .from('wallets')
        .select()
        .filter('id', 'in', '(${walletIds.join(',')})');
        
    return Response.json(body: response);
  }

  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json() as Map<String, dynamic>;
    body['owner_user_id'] = user.id;

    final response =
        await supabase.from('wallets').insert(body).select().single();
    final walletId = response['id'];

    await supabase.from('wallet_users').insert({
      'wallet_id': walletId,
      'user_id': user.id,
      'role': 'owner',
    });

    return Response.json(statusCode: HttpStatus.created, body: response);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}