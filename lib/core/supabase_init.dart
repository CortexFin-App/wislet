import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wislet/core/constants/app_constants.dart';

class Supa {
  static SupabaseClient get client => Supabase.instance.client;
}

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
    debug: false,
  );
}
