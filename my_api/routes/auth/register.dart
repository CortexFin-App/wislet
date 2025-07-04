import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

Future<Response> onRequest(RequestContext context) async {
  // Цей роут працює тільки для POST запитів
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final supabase = context.read<SupabaseClient>();
    final body = await context.request.json() as Map<String, dynamic>;

    // Просто намагаємось зареєструвати користувача
    await supabase.auth.signUp(
      email: body['email'] as String,
      password: body['password'] as String,
    );

    // Якщо помилки не було - повертаємо успіх
    return Response(body: 'Success! Check your email for confirmation.');
  } catch (e) {
    // Якщо була помилка - повертаємо її текст
    return Response(statusCode: 500, body: e.toString());
  }
}