import 'package:dart_frog/dart_frog.dart';

Handler middleware(Handler handler) {
  // Просто передаємо запит далі без жодних перевірок,
  // логування чи додавання Supabase в контекст.
  return handler;
}