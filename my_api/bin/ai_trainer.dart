import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  print('AI Trainer starting...');

  // --- ІНТЕГРОВАНО ---
  // Використовуємо правильні, стандартні імена змінних
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseServiceKey = Platform.environment['SUPABASE_SERVICE_KEY'];
  // --- КІНЕЦЬ ІНТЕГРАЦІЇ ---

  if (supabaseUrl == null || supabaseServiceKey == null) {
    print('Error: SUPABASE_URL or SUPABASE_SERVICE_KEY not found in environment variables.');
    return;
  }

  final supabase = SupabaseClient(supabaseUrl, supabaseServiceKey);
  const confidenceThreshold = 10;

  try {
    final response = await supabase
      .from('ai_learning_log')
      .select('keyword, category_name')
      .gt('submission_count', confidenceThreshold);

    if (response.isEmpty) {
      print('No new high-confidence suggestions found. Exiting.');
      return;
    }
    
    final Map<String, String> newGlobalDictionary = {};
    for (final record in response) {
      final keyword = record['keyword'] as String?;
      final categoryName = record['category_name'] as String?;
      if (keyword != null && categoryName != null) {
        newGlobalDictionary[keyword] = categoryName;
      }
    }
    
    final jsonString = jsonEncode(newGlobalDictionary);
    final jsonBytes = utf8.encode(jsonString);

    const bucketName = 'ai-dictionaries';
    const fileName = 'global_lexicon.json';

    await supabase.storage
      .from(bucketName)
      .uploadBinary(
        fileName,
        jsonBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

    print('Successfully updated global AI dictionary with ${newGlobalDictionary.length} keywords.');

  } catch (e) {
    print('Error during AI training: $e');
  } finally {
      print('AI Trainer finished.');
  }
}