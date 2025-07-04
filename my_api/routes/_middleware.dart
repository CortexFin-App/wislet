import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:supabase/supabase.dart';

Handler middleware(Handler handler) {
  // Надаємо Supabase клієнт у контекст
  return handler.use(
    provider<SupabaseClient>(
      (_) {
        final supabaseUrl = Platform.environment['SUPABASE_URL']!;
        final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY']!;
        return SupabaseClient(supabaseUrl, supabaseAnonKey);
      },
    ),
  );
}