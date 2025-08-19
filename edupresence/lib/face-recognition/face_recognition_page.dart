import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:edupresence/helper/ml_helper.dart';
import 'package:image/image.dart' as img;

class FaceRecognitionPage extends StatefulWidget {
  final String userId; // ID akun user untuk cek database
  const FaceRecognitionPage({super.key, required this.userId});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  late MLHelper _mlHelper;
  CameraController? _cameraController;
  bool _isProcessing = false;
  Interpreter? _detectorInterpreter;
  Interpreter? _recognizerInterpreter;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModels();
    _mlHelper = MLHelper();
    _mlHelper.loadModels(
      "assets/models/face_detection_front.tflite",
      "assets/models/mobilefacenet.tflite",
    );
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (cam) => cam.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future<void> _loadModels() async {
    _detectorInterpreter = await Interpreter.fromAsset(
      'face_detection_front.tflite',
    );
    _recognizerInterpreter = await Interpreter.fromAsset(
      'mobilefacenet.tflite',
    );
  }

  img.Image _convertCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image convertedImage = img.Image(width: width, height: height);

    final Plane planeY = image.planes[0];
    final Plane planeU = image.planes[1];
    final Plane planeV = image.planes[2];

    final Uint8List yBuffer = planeY.bytes;
    final Uint8List uBuffer = planeU.bytes;
    final Uint8List vBuffer = planeV.bytes;

    int uvRowStride = planeU.bytesPerRow;
    int uvPixelStride = planeU.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        int index = y * width + x;

        final yp = yBuffer[index];
        final up = uBuffer[uvIndex];
        final vp = vBuffer[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        convertedImage.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    return convertedImage;
  }

  Future<img.Image?> _cropFace(
    CameraImage cameraImage,
    List<double> boundingBox,
  ) async {
    try {
      // Convert CameraImage ke format image.Image (RGB)
      final img.Image convertedImage = _convertCameraImage(cameraImage);

      // Ambil bounding box wajah (x, y, width, height)
      final double x = boundingBox[0];
      final double y = boundingBox[1];
      final double w = boundingBox[2];
      final double h = boundingBox[3];

      // Crop wajah
      final img.Image croppedFace = img.copyCrop(
        convertedImage,
        x: x.toInt(),
        y: y.toInt(),
        width: w.toInt(),
        height: h.toInt(),
      );

      // Resize ke input MobileFaceNet (112x112 px)
      final img.Image resizedFace = img.copyResize(
        croppedFace,
        width: 112,
        height: 112,
      );

      return resizedFace;
    } catch (e) {
      print("Crop face error: $e");
      return null;
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // 1. Convert ke RGB
      final img.Image rgbImage = _convertCameraImage(image);

      // 2. Deteksi wajah
      final rect = await _mlHelper.detectFaces(rgbImage);
      if (rect == null) {
        print("No face detected");
        _isProcessing = false;
        return;
      }

      // 3. Crop wajah
      final faceImage = await _cropFace(
        rgbImage as CameraImage,
        rect.cast<double>(),
      );
      if (faceImage == null) {
        print("Failed to crop face");
        _isProcessing = false;
        return;
      }

      // 4. Ambil embedding dari wajah yg di-scan kamera
      final embedding = await _mlHelper.getEmbedding(faceImage as img.Image);

      // 5. Ambil embedding yg tersimpan di Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection("students")
          .doc(widget.userId)
          .get();

      if (!snapshot.exists || !snapshot.data()!.containsKey("embedding")) {
        print("❌ Tidak ada data wajah di database");
        _isProcessing = false;
        return;
      }

      final storedEmbedding = List<double>.from(snapshot.data()!["embedding"]);

      // 6. Hitung jarak / similarity
      final distance = _calculateEuclideanDistance(embedding, storedEmbedding);

      print("🔍 Distance: $distance");

      // 7. Threshold → misalnya < 1.0 dianggap cocok
      if (distance < 1.0) {
        print("✅ Wajah cocok, absensi diterima");
        Navigator.pop(context, true);
      } else {
        print("❌ Wajah tidak cocok");
      }
    } catch (e) {
      print("Error processing camera image: $e");
    }

    _isProcessing = false;
  }

  double _calculateEuclideanDistance(List<double> e1, List<double> e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += (e1[i] - e2[i]) * (e1[i] - e2[i]);
    }
    return sqrt(sum);
  }

  Future<bool> _checkEmbeddingFromDatabase(String userId) async {
    // TODO: Ambil embedding dari database dan bandingkan
    // return true jika cocok
    return false;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _detectorInterpreter?.close();
    _recognizerInterpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.green),
              ),
            ),
        ],
      ),
    );
  }
}
