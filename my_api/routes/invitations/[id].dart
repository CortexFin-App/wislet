import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final userId = context.read<String>(); // ID того, хто приймає запрошення

  if (context.request.method == HttpMethod.put) {
    try {
      final invitation = await supabase.from('invitations').select().eq('id', id).single();
      
      if(invitation['status'] != 'pending') {
        return Response(statusCode: HttpStatus.badRequest, body: 'Invitation already used or declined.');
      }
      
      await supabase.from('wallet_users').insert({
        'wallet_id': invitation['wallet_id'],
        'user_id': userId,
        'role': 'editor',
      });

      await supabase.from('invitations').update({'status': 'accepted'}).eq('id', id);
      
      return Response(statusCode: HttpStatus.noContent);
    } catch (e) {
      return Response(statusCode: HttpStatus.internalServerError, body: e.toString());
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}