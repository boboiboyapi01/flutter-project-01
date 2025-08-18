import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class MLHelper {
  late Interpreter _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;

  MLHelper(String modelPath) {
    _loadModel(modelPath);
  }

  /// Load model TFLite
  Future<void> _loadModel(String modelPath) async {
    try {
      _interpreter = await Interpreter.fromAsset(modelPath);
      _inputShape = _interpreter.getInputTensor(0).shape;
      _outputShape = _interpreter.getOutputTensor(0).shape;
      print("Model loaded: input=$_inputShape, output=$_outputShape");
    } catch (e) {
      print("Error while loading model: $e");
    }
  }

  /// Preprocess: convert image -> Float32 input tensor
  TensorImage _preprocess(img.Image image) {
    final inputSize = _inputShape[1]; // biasanya [1, 224, 224, 3]
    final resized = img.copyResize(image, width: inputSize, height: inputSize);

    var buffer = Float32List(inputSize * inputSize * 3).buffer;
    var byteData = buffer.asFloat32List();

    int index = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        byteData[index++] = (img.getRed(pixel) / 255.0);
        byteData[index++] = (img.getGreen(pixel) / 255.0);
        byteData[index++] = (img.getBlue(pixel) / 255.0);
      }
    }

    return TensorImage(byteData, _inputShape);
  }

  /// Jalankan inference
  Future<List<double>> runInference(img.Image image) async {
    final inputTensor = _preprocess(image);

    // Buat buffer input & output
    var input = inputTensor.buffer;
    var output = List.filled(_outputShape.reduce((a, b) => a * b), 0).reshape(_outputShape);

    _interpreter.run(input, output);

    return output.reshape([output.length]).cast<double>();
  }

  /// Release resources
  void close() {
    _interpreter.close();
  }
}

/// Helper untuk bungkus data tensor
class TensorImage {
  final Float32List buffer;
  final List<int> shape;
  TensorImage(this.buffer, this.shape);
}
