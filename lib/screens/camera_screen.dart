// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'history_screen.dart';
//
// class CameraScreen extends StatefulWidget {
//   final List<CameraDescription> cameras;
//   const CameraScreen({super.key, required this.cameras});
//
//   @override
//   State<CameraScreen> createState() => _CameraScreenState();
// }
//
// class _CameraScreenState extends State<CameraScreen> {
//   CameraController? _controller;
//   final DatabaseReference _dbRef =
//   FirebaseDatabase.instance.ref().child('camera_history');
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();
//   }
//
//   Future<void> _initializeCamera() async {
//     if (widget.cameras.isEmpty) return;
//
//     _controller = CameraController(
//       widget.cameras.first,
//       ResolutionPreset.max,
//       enableAudio: false,
//     );
//
//     await _controller!.initialize();
//     if (mounted) setState(() {});
//   }
//
//   @override
//   void dispose() {
//     _controller?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: _controller == null || !_controller!.value.isInitialized
//           ? const Center(
//           child: CircularProgressIndicator(color: Colors.greenAccent))
//           : Stack(
//         children: [
//           Positioned.fill(child: CameraPreview(_controller!)),
//
//           // History button
//           Positioned(
//             top: 40,
//             right: 20,
//             child: GestureDetector(
//               onTap: () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => HistoryScreen()),
//               ),
//               child: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.3),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.history,
//                     color: Colors.greenAccent, size: 28),
//               ),
//             ),
//           ),
//
//           // Capture button
//           Positioned(
//             bottom: 50,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: GestureDetector(
//                 onTap: _captureAndSend,
//                 child: Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     border:
//                     Border.all(color: Colors.greenAccent, width: 4),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _captureAndSend() async {
//     if (!_controller!.value.isInitialized) return;
//
//     final file = await _controller!.takePicture();
//     final predictedClass = await _sendImageToBackend(file.path);
//
//     _showPredictionDialog(file.path, predictedClass);
//   }
//
//   Future<String> _sendImageToBackend(String path) async {
//     // Replace with actual backend call
//     await Future.delayed(const Duration(seconds: 1));
//     return "Gas Detected";
//   }
//
//   void _showPredictionDialog(String imagePath, String predictedClass) {
//     showDialog(
//       context: context,
//       builder: (_) {
//         return Dialog(
//           backgroundColor: Colors.black.withOpacity(0.8),
//           shape:
//           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: Stack(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Image.file(File(imagePath), height: 250, width: 290),
//                     const SizedBox(height: 12),
//                     Text(
//                       predictedClass,
//                       style: const TextStyle(
//                         color: Colors.greenAccent,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.greenAccent),
//                       onPressed: () => _saveToFirebase(imagePath, predictedClass),
//                       child: const Text('Save'),
//                     ),
//                   ],
//                 ),
//               ),
//               Positioned(
//                 top: 8,
//                 right: 8,
//                 child: GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child:
//                   const Icon(Icons.close, color: Colors.greenAccent, size: 28),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Future<void> _saveToFirebase(String imagePath, String predictedClass) async {
//     // Optional: Encode image to Base64 if needed
//     final bytes = await File(imagePath).readAsBytes();
//     final base64Image = base64Encode(bytes);
//
//     await _dbRef.push().set({
//       'imagePath': imagePath,
//       'prediction': predictedClass,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Saved to Firebase DB!')),
//       );
//       Navigator.pop(context);
//     }
//   }
// }
//
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../components/prediction_dialog.dart';
import 'auth/login_page.dart';
import 'history_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref().child('camera_history');

  int _currentCameraIndex = 0;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 8.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    _controller = CameraController(
      widget.cameras[_currentCameraIndex],
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _controller!.initialize();

    _minZoom = await _controller!.getMinZoomLevel();
    _maxZoom = await _controller!.getMaxZoomLevel();

    if (mounted) setState(() {});
  }

  void _switchCamera() async {
    if (widget.cameras.length < 2) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % widget.cameras.length;
    await _controller?.dispose();
    _initializeCamera();
  }

  void _setZoom(double zoom) async {
    _currentZoom = zoom;
    await _controller?.setZoomLevel(zoom);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent))
          : Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onScaleUpdate: (details) {
                double newZoom = (_currentZoom * details.scale)
                    .clamp(_minZoom, _maxZoom);
                _setZoom(newZoom);
              },
              child: CameraPreview(_controller!),
            ),
          ),

          // Logout button
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: _confirmLogout,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout,
                    color: Colors.greenAccent, size: 28),
              ),
            ),
          ),

          // History button
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history,
                    color: Colors.greenAccent, size: 28),
              ),
            ),
          ),

          // Switch camera button
          Positioned(
            top: 40,
            right: 80,
            child: GestureDetector(
              onTap: _switchCamera,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cameraswitch,
                    color: Colors.greenAccent, size: 28),
              ),
            ),
          ),

          // Capture button
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _captureAndSend,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                    Border.all(color: Colors.greenAccent, width: 4),
                  ),
                ),
              ),
            ),
          ),

          // Zoom slider
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: Slider(
              value: _currentZoom,
              min: _minZoom,
              max: _maxZoom,
              activeColor: Colors.greenAccent,
              inactiveColor: Colors.greenAccent.withOpacity(0.3),
              onChanged: (value) => _setZoom(value),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndSend() async {
    if (!_controller!.value.isInitialized) return;

    final file = await _controller!.takePicture();
    final predictedClass = await _sendImageToBackend(file.path);

    showDialog(
      context: context,
      builder: (_) => PredictionDialog(
        imagePath: file.path,
        predictedClass: predictedClass,
        onSave: () => _saveToFirebase(file.path, predictedClass),
      ),
    );
  }

  Future<String> _sendImageToBackend(String path) async {
    await Future.delayed(const Duration(seconds: 1));
    return "Gas Detected";
  }

  Future<void> _saveToFirebase(String imagePath, String predictedClass) async {
    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);

    await _dbRef.push().set({
      'imagePath': imagePath,
      'prediction': predictedClass,
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved to Firebase DB!')),
      );
      Navigator.pop(context); // Close dialog
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "Logout",
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: const Text(
          "Do you want to logout?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Clear all secure storage
              final storage = const FlutterSecureStorage();
              await storage.deleteAll();

              // Sign out from Firebase
              await FirebaseAuth.instance.signOut();

              // Redirect to login
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                      (route) => false,
                );
              }
            },
            child: const Text(
              "Yes",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

}
