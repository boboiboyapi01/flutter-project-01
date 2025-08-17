import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEmbeddingPage extends StatefulWidget {
  final String userId; // ID akun user untuk simpan data embedding
  const FaceEmbeddingPage({super.key, required this.userId});

  @override
  State<FaceEmbeddingPage> createState() => _FaceEmbeddingPageState();
}

class _FaceEmbeddingPageState extends State<FaceEmbeddingPage> {
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
    // TODO: Extract embedding vector dari wajah terdeteksi

    // Simpan embedding ke database
    await _saveEmbeddingToDatabase(widget.userId, Float32List(192));

    Navigator.pop(context, true); // selesai dan kembali
    _isProcessing = false;
  }

  Future<void> _saveEmbeddingToDatabase(
      String userId, Float32List embedding) async {
    // TODO: Implement simpan embedding ke Firebase/Supabase
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

