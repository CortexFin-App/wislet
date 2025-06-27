import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context, String token) async {
  final supabase = context.read<SupabaseClient>();
  final user = (await supabase.auth.getUser(context.request.headers['Authorization']!.substring(7))).user!;
  
  if (context.request.method == HttpMethod.put) {
    try {
      final invitation = await supabase.from('invitations').select().eq('token', token).single();
      
      if(invitation['status'] != 'pending') {
        return Response(statusCode: HttpStatus.badRequest, body: 'Invitation already used or declined.');
      }
      
      await supabase.from('wallet_users').insert({
        'wallet_id': invitation['wallet_id'],
        'user_id': user.id,
        'role': 'editor',
      });

      await supabase.from('invitations').update({'status': 'accepted'}).eq('token', token);
      
      return Response(statusCode: HttpStatus.noContent);
    } catch (e) {
      return Response(statusCode: HttpStatus.internalServerError, body: e.toString());
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}