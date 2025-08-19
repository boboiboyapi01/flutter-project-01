import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MLHelper {
  Interpreter? _detector; // face detection
  Interpreter? _embedder; // face embedding

  /// 🔹 Load both models
  Future<void> loadModels(String s, String ) async {
    _detector = await _loadModelFromAssets(
      "assets/models/face_detection_front.tflite",
    );
    _embedder = await _loadModelFromAssets(
      "assets/models/mobilefacenet.tflite",
    );
  }

  /// 🔹 Helper: copy model from assets → temp file
  Future<Interpreter> _loadModelFromAssets(String assetPath) async {
    final rawAssetFile = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File("${tempDir.path}/${assetPath.split('/').last}");
    await file.writeAsBytes(rawAssetFile.buffer.asUint8List());
    return Interpreter.fromFile(file);
  }

  /// 🔹 Run detection → return bounding boxes
  Future<List<Rect>> detectFaces(img.Image inputImage) async {
    if (_detector == null) throw Exception("Face detection model not loaded");

    final resized = img.copyResize(inputImage, width: 128, height: 128);

    var input = List.generate(128 * 128 * 3, (i) {
      final x = i % 128;
      final y = (i ~/ 128) % 128;
      final pixel = inputImage.getPixel(x, y);

      final r = pixel.rNormalized;
      final g = pixel.gNormalized;
      final b = pixel.bNormalized;

      return [r, g, b][i % 3]; // ambil channel sesuai index
    }).reshape([1, 128, 128, 3]);

    var output = List.filled(4, 0.0).reshape([1, 4]);
    _detector!.run(input, output);

    final box = output[0]; // [x1,y1,x2,y2]
    return [
      Rect.fromLTWH(
        box[0] * inputImage.width,
        box[1] * inputImage.height,
        (box[2] - box[0]) * inputImage.width,
        (box[3] - box[1]) * inputImage.height,
      ),
    ];
  }

  /// 🔹 Run embedding → return vector wajah
  Future<List<double>> getEmbedding(img.Image faceImage) async {
    if (_embedder == null) throw Exception("Face embedding model not loaded");

    // 🔹 Resize ke 112x112
    final resized = img.copyResize(faceImage, width: 112, height: 112);

    // 🔹 Convert ke float32 [1,112,112,3]
    var input = List.generate(1 * 112 * 112 * 3, (i) {
      final pixel = resized.getPixel(i % 112, (i ~/ 112) % 112);

      final r = pixel.rNormalized;
      final g = pixel.gNormalized;
      final b = pixel.bNormalized;

      // urutkan RGB
      if (i % 3 == 0) return r;
      if (i % 3 == 1) return g;
      return b;
    }).reshape([1, 112, 112, 3]);

    // 🔹 Output embedding (128 dimensi)
    var output = List.filled(1 * 128, 0.0).reshape([1, 128]);

    _embedder!.run(input, output);

    return List<double>.from(output.reshape([128]));
  }
}
