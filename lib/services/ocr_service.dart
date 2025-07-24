import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class OcrService {
  final SupabaseClient _supabase;

  OcrService(this._supabase);

  Future<String?> processImage(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final imageBase64 = base64Encode(imageBytes);

    final response = await _supabase.functions.invoke(
      'ocr',
      body: {'image': imageBase64},
    );
    
    if (response.status != 200) {
      throw Exception(response.data?['error'] ?? 'OCR function failed with status ${response.status}');
    }

    if (response.data != null && response.data['text'] is String) {
      return response.data['text'] as String;
    }
    
    return null;
  }
}