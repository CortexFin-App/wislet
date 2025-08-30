import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sage_wallet_reborn/core/env/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap() async {
  await dotenv.load();
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabaseAnonKey,
  );
}
