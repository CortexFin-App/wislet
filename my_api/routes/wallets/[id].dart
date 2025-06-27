import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;
import '../../src/supabase_client.dart';

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

  if (context.request.method == HttpMethod.get) {
    final response = await supabase.from('wallets').select().eq('id', walletId).single();
    return Response.json(body: response);
  }

  final canEdit = await supabase.canUserEdit(user.id, walletId);
  if (!canEdit) {
    return Response(statusCode: HttpStatus.forbidden, body: 'Insufficient permissions');
  }

  if (context.request.method == HttpMethod.put) {
    final body = await context.request.json() as Map<String, dynamic>;
    final response = await supabase.from('wallets').update(body).eq('id', walletId).select().single();
    return Response.json(body: response);
  }

  if (context.request.method == HttpMethod.delete) {
    await supabase.from('wallets').delete().eq('id', walletId);
    return Response(statusCode: HttpStatus.noContent);
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}