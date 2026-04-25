// lib/core/bootstrap/supabase_env.dart
class SupabaseEnv {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zfnrlfsjqfukaoliaxrr.supabase.co',
  );
  static const anon = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpmbnJsZnNqcWZ1a2FvbGlheHJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4OTM2NDIsImV4cCI6MjA5MjQ2OTY0Mn0.CRcO5tzwNshfDSsANVtEwwckiSxd192jB4-jzxPzaxA',
  );
}
