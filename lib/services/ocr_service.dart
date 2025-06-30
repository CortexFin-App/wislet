import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http; // Нам потрібен http
import 'api_client.dart'; // Припускаю, що ваш ApiClient знаходиться тут

class OcrService {
  final ApiClient _apiClient;

  OcrService(this._apiClient);

  Future<String?> processImage(String imagePath) async {
    try {
      // Читаємо файл картинки і кодуємо його в Base64
      final imageBytes = await File(imagePath).readAsBytes();
      final imageBase64 = base64Encode(imageBytes);

      // Відправляємо POST-запит на наш бекенд
      final response = await _apiClient.post(
        '/ocr', // Наш новий ендпоінт
        body: {'image': imageBase64},
      );

      // Повертаємо розпізнаний текст
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