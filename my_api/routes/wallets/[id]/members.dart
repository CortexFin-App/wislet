import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../../src/supabase_client.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final userId = context.read<String>();
  final walletId = int.tryParse(id);

  if (walletId == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  if (!await supabase.isUserOwner(userId, walletId)) {
    return Response(statusCode: HttpStatus.forbidden, body: 'Only owner can manage members');
  }

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;
    final targetUserId = body['user_id'] as String;
    final newRole = body['role'] as String;

    await supabase
      .from('wallet_users')
      .update({'role': newRole})
      .eq('wallet_id', walletId)
      .eq('user_id', targetUserId);
    return Response(statusCode: HttpStatus.noContent);
  }

  if (context.request.method == HttpMethod.delete) {
    final body = await context.request.json() as Map<String, dynamic>;
    final targetUserId = body['user_id'] as String;

    if (userId == targetUserId) {
        return Response(statusCode: HttpStatus.badRequest, body: 'Owner cannot be removed');
    }
    
    await supabase
      .from('wallet_users')
      .delete()
      .eq('wallet_id', walletId)
      .eq('user_id', targetUserId);
    return Response(statusCode: HttpStatus.noContent);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}