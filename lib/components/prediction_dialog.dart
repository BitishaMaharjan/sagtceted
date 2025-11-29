import 'dart:io';
import 'package:flutter/material.dart';

class PredictionDialog extends StatelessWidget {
  final String imagePath;
  final String predictedClass;
  final VoidCallback onSave;

  const PredictionDialog({
    Key? key,
    required this.imagePath,
    required this.predictedClass,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(File(imagePath), height: 250, width: 290),
                const SizedBox(height: 12),
                Text(
                  predictedClass,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent),
                  onPressed: onSave,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close,
                  color: Colors.greenAccent, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
