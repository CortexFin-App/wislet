import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ініціалізація Supabase, але тільки якщо є обидва ключі.
/// Інакше — тихо пропускаємо (офлайн режим).
class SupabaseBootstrap {
  static bool _done = false;

  static Future<void> ensureInitialized() async {
    if (_done) return;

    // Завантажимо .env, якщо він є (не крешимося, якщо його немає)
    try {
      await dotenv.load();
    } catch (_) {}

    final url = (dotenv.maybeGet('SUPABASE_URL') ?? '').trim();
    final anon = (dotenv.maybeGet('SUPABASE_ANON') ?? '').trim();

    if (url.isEmpty || anon.isEmpty) {
      if (kDebugMode) {
        debugPrint('[SupabaseBootstrap] Keys missing → starting OFFLINE');
      }
      _done = true;
      return;
    }

    await Supabase.initialize(url: url, anonKey: anon);
    _done = true;
  }
}
