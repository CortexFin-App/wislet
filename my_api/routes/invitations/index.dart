import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context) async {
  final supabase = context.read<SupabaseClient>();
  final user = context.read<User>();

  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json() as Map<String, dynamic>;
    final walletId = body['wallet_id'] as int?;
    if (walletId == null) {
      return Response(statusCode: HttpStatus.badRequest);
    }

    final isOwner = await supabase.isUserOwner(user.id, walletId);
    if (!isOwner) {
      return Response(statusCode: HttpStatus.forbidden);
    }

    final invData = {
      'wallet_id': walletId,
      'inviter_id': user.id,
    };
    final response =
        await supabase.from('invitations').insert(invData).select().single();
    return Response.json(body: response);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}