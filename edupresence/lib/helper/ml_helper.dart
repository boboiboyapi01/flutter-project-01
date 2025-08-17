import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class MLHelper {
  Interpreter? _interpreter;

  /// Load TFLite model
  Future<void> loadModel({String modelPath = 'assets/models/face_model.tflite'}) async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      print("✅ Model loaded: $modelPath");
    } catch (e) {
      print("❌ Failed to load model: $e");
    }
  }

  /// Convert image bytes (Uint8List) to Float32 tensor (simple normalization)
  TensorBuffer imageToTensor(Uint8List imageData, {int inputSize = 112}) {
    // NOTE: di sini kamu bisa pakai library image (package:image)
    // untuk resize dan convert ke RGB
    // supaya hasilnya [inputSize, inputSize, 3]

    // sementara dummy buffer (1D) biar gampang dulu
    List<double> normalized = imageData.map((e) => e / 255.0).toList();

    return TensorBuffer.createFixedSize([1, inputSize, inputSize, 3], TfLiteType.float32)
      ..loadList(normalized, shape: [1, inputSize, inputSize, 3]);
  }

  /// Run inference dan return embedding
  List<double> runEmbedding(TensorBuffer inputBuffer, {int embeddingSize = 192}) {
    if (_interpreter == null) {
      throw Exception("Interpreter not initialized. Call loadModel() first.");
    }

    // Prepare output buffer
    TensorBuffer outputBuffer = TensorBuffer.createFixedSize([1, embeddingSize], TfLiteType.float32);

    // Run inference
    _interpreter!.run(inputBuffer.buffer, outputBuffer.buffer);

    return outputBuffer.getDoubleList();
  }

  void close() {
    _interpreter?.close();
  }
}

