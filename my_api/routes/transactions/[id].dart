import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart' hide HttpMethod;

Future<Response> onRequest(RequestContext context, String id) async {
  final supabase = context.read<SupabaseClient>();
  final transactionId = int.tryParse(id);

  if (transactionId == null) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _get(supabase, transactionId);
    case HttpMethod.put:
      return _put(context, supabase, transactionId);
    case HttpMethod.delete:
      return _delete(supabase, transactionId);
    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _get(SupabaseClient supabase, int id) async {
  final response = await supabase
      .from('transactions')
      .select('*, categories(*)')
      .eq('id', id)
      .single();
  return Response.json(body: response);
}

Future<Response> _put(
  RequestContext context,
  SupabaseClient supabase,
  int id,
) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final response = await supabase
      .from('transactions')
      .update(body)
      .eq('id', id)
      .select()
      .single();
  return Response.json(body: response);
}

Future<Response> _delete(SupabaseClient supabase, int id) async {
  await supabase.from('transactions').delete().eq('id', id);
  return Response(statusCode: HttpStatus.noContent);
}