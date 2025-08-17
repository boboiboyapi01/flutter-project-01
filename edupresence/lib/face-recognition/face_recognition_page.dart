import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class FaceRecognitionPage extends StatefulWidget {
  final String userId; // ID akun user untuk cek database
  const FaceRecognitionPage({super.key, required this.userId});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  Interpreter? _detectorInterpreter;
  Interpreter? _recognizerInterpreter;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModels();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front);

    _cameraController = CameraController(frontCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
    _cameraController!.startImageStream(_processCameraImage);
    setState(() {});
  }

  Future<void> _loadModels() async {
    _detectorInterpreter =
        await Interpreter.fromAsset('face_detection_front.tflite');
    _recognizerInterpreter =
        await Interpreter.fromAsset('mobilefacenet.tflite');
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    // TODO: Preprocessing frame & detect face
    // TODO: Extract embedding vector from detected face

    // Contoh pseudo-code cek embedding di database
    bool faceMatch = await _checkEmbeddingFromDatabase(widget.userId);

    if (faceMatch) {
      Navigator.pop(context, true); // return success
    } else {
      Navigator.pushReplacementNamed(context, '/face-embedding');
    }

    _isProcessing = false;
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

