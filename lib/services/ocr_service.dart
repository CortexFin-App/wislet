import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class OcrService {
  OcrService(this._supabase);
  final SupabaseClient _supabase;

  Future<String?> processImage(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final imageBase64 = base64Encode(imageBytes);

    final response = await _supabase.functions.invoke(
      'ocr',
      body: {'image': imageBase64},
    );

    if (response.status != 200) {
      final responseData = response.data as Map<String, dynamic>?;
      throw Exception(
        responseData?['error'] ??
            'OCR function failed with status ${response.status}',
      );
    }

    final responseData = response.data as Map<String, dynamic>?;
    if (responseData != null && responseData['text'] is String) {
      return responseData['text'] as String;
    }

    return null;
  }
}
