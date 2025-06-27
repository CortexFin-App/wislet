import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();

  if (context.request.method == HttpMethod.get) {
    final walletId =
        int.tryParse(context.request.url.queryParameters['walletId'] ?? '');
    if (walletId == null) return Response(statusCode: HttpStatus.badRequest);

    final isMember = await supabase.isUserMember(user.id, walletId);
    if (!isMember) return Response(statusCode: HttpStatus.forbidden);

    final data = await supabase
        .from('repeating_transactions')
        .select()
        .eq('wallet_id', walletId);
    return Response.json(body: data);
  }

  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json() as Map<String, dynamic>;
    final walletId = body['wallet_id'] as int?;
    if (walletId == null) return Response(statusCode: HttpStatus.badRequest);

    final canEdit = await supabase.canUserEdit(user.id, walletId);
    if (!canEdit) return Response(statusCode: HttpStatus.forbidden);

    body['user_id'] = user.id;
    final data = await supabase
        .from('repeating_transactions')
        .insert(body)
        .select()
        .single();
    return Response.json(statusCode: HttpStatus.created, body: data);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}