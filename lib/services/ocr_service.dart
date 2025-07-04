import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class OcrService {
  final ApiClient _apiClient;

  OcrService(this._apiClient);

  Future<String?> processImage(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      final response = await _apiClient.post(
        '/ocr',
        body: {'image': imageBase64},
      );

      if (response != null && response['text'] is String) {
        return response['text'] as String;
      }
      return null;
    } catch (e) {
      print("OCR Service Error: $e");
      return null;
    }
  }
}