import 'package:flutter/material.dart';
import 'face_recognition_logic.dart';

class FaceRecognitionPage extends StatelessWidget {
  final String userId;
  const FaceRecognitionPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF12323F),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: const Text(
              "Face Recognition",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Camera logic
          Expanded(
            child: FaceRecognitionLogic(userId: userId),
          ),

          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF12323F),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: const [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 8),
                Text(
                  "Selamat datang di EduPresence",
                  style: TextStyle(color: Colors.cyan, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
