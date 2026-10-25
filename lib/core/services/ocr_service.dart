import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wraps Google ML Kit Text Recognizer for offline on-device OCR.
/// Supports Latin script; extend with [TextRecognitionScript.chinese],
/// [TextRecognitionScript.korean] etc. as needed.
class OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Extracts all text from the image at [imagePath].
  /// Returns a newline-separated string of detected lines.
  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final RecognizedText recognizedText =
        await _recognizer.processImage(inputImage);
    return recognizedText.text;
  }

  void dispose() {
    _recognizer.close();
  }
}
