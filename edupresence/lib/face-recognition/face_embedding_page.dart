import 'package:flutter/material.dart';
import 'face_embedding_logic.dart';

class FaceEmbeddingPage extends StatelessWidget {
  final String userId;
  const FaceEmbeddingPage({super.key, required this.userId});

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
              "Face Embedding",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Camera logic
          Expanded(
            child: FaceEmbeddingLogic(userId: userId),
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
                  "Sesuaikan wajah di tengah layar",
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
