import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  // Ініціалізація розпізнавача значно простіша
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String?> processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print("Помилка розпізнавання: $e");
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}