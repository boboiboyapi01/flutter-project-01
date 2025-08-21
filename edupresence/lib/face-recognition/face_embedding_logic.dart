import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupresence/helper/ml_helper.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class FaceEmbeddingLogic extends StatefulWidget {
  final String userId; // ID akun user untuk simpan data embedding
  const FaceEmbeddingLogic({super.key, required this.userId});

  @override
  State<FaceEmbeddingLogic> createState() => _FaceEmbeddingLogicState();
}

class _FaceEmbeddingLogicState extends State<FaceEmbeddingLogic> {
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
    _mlHelper.loadModels("assets/models/face_detection_front.tflite",
        "assets/models/mobilefacenet.tflite");
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
    // 🔹 1. Convert CameraImage (YUV → RGB → image package)
    final img.Image rgbImage = _convertCameraImage(image);

    // 🔹 2. Deteksi wajah → ambil bounding box
    final rect = await _mlHelper.detectFaces(rgbImage);
    if (rect == null) {
      print("No face detected");
      _isProcessing = false;
      return;
    }

    // 🔹 3. Crop wajah pakai bounding box
    final faceImage = _cropFace(rgbImage as CameraImage, rect.cast<double>());
    if (faceImage == null) {
      print("Failed to crop face");
      _isProcessing = false;
      return;
    }

    // 🔹 4. Preprocess & dapatkan embedding vector
    final embedding = await _mlHelper.getEmbedding(faceImage as img.Image);

    // 🔹 5. Simpan embedding ke Firestore
    await _saveEmbeddingToDatabase(
      widget.userId,
      Float32List.fromList(embedding),
    );

    Navigator.pop(context, true); // selesai dan kembali
  } catch (e) {
    print("Error processing camera image: $e");
  }

  _isProcessing = false;
}


  Future<void> _saveEmbeddingToDatabase(
    String userId,
    Float32List embedding,
  ) async {
    try {
      // Convert Float32List → List<double> untuk disimpan di Firestore
      final List<double> embeddingList = embedding.toList();

      await FirebaseFirestore.instance.collection("students").doc(userId).set({
        "embedding": embeddingList,
        "createdAt": DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      print("✅ Embedding berhasil disimpan untuk $userId");
    } catch (e) {
      print("❌ Gagal menyimpan embedding: $e");
    }
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
                child: CircularProgressIndicator(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}
