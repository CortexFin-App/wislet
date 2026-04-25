import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wislet/core/bootstrap/supabase_env.dart';

class SupabaseBootstrap {
  static bool _done = false;

  static Future<void> ensureInitialized() async {
    if (_done) return;

    const url = SupabaseEnv.url;
    const anon = SupabaseEnv.anon;

    if (url.isEmpty || anon.isEmpty) {
      if (kDebugMode) {
        debugPrint('[SupabaseBootstrap] Keys missing → starting OFFLINE');
      }
      _done = true;
      return;
    }

    try {
      await Supabase.initialize(url: url, anonKey: anon);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseBootstrap] Init failed → $e');
      }
    }
    _done = true;
  }
}
