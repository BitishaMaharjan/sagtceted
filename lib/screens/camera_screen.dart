import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
  bool _isProcessing = false;
  FlashMode _currentFlashMode = FlashMode.off;
  bool _showGrid = false;


  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (widget.cameras.isEmpty) return;

    _controller = CameraController(
      widget.cameras[_currentCameraIndex],
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();

    // Set optimal settings for better quality
    await _controller!.setFocusMode(FocusMode.auto);
    await _controller!.setExposureMode(ExposureMode.auto);
    await _controller!.setFlashMode(_currentFlashMode);

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

  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Cycle through flash modes: off -> auto -> on -> torch -> off
    switch (_currentFlashMode) {
      case FlashMode.off:
        _currentFlashMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        _currentFlashMode = FlashMode.always;
        break;
      case FlashMode.always:
        _currentFlashMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        _currentFlashMode = FlashMode.off;
        break;
    }

    await _controller!.setFlashMode(_currentFlashMode);
    if (mounted) setState(() {});
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
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
          // Full screen camera preview with standard aspect ratio
          Positioned.fill(
            child: GestureDetector(
              onScaleUpdate: (details) {
                double newZoom =
                (_currentZoom * details.scale).clamp(_minZoom, _maxZoom);
                _setZoom(newZoom);
              },
              onTapDown: (details) async {
                // Add tap to focus
                if (_controller != null && _controller!.value.isInitialized) {
                  final offset = Offset(
                    details.localPosition.dx / context.size!.width,
                    details.localPosition.dy / context.size!.height,
                  );
                  await _controller!.setFocusPoint(offset);
                  await _controller!.setExposurePoint(offset);
                }
              },
              child: Center(
                child: Stack(
                  children: [
                    CameraPreview(_controller!),
                    // Grid overlay
                    if (_showGrid)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GridPainter(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay when processing
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.greenAccent,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing image...',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top bar with buttons (iPhone style)
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Flash toggle button
                  GestureDetector(
                    onTap: _isProcessing ? null : _toggleFlash,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Icon(
                        _getFlashIcon(),
                        color: _isProcessing
                            ? Colors.grey
                            : (_currentFlashMode == FlashMode.off
                            ? Colors.white70
                            : Colors.greenAccent),
                        size: 24,
                      ),
                    ),
                  ),
                  // Grid button
                  GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : () {
                      setState(() {
                        _showGrid = !_showGrid;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Icon(
                        Icons.grid_on,
                        color: _isProcessing
                            ? Colors.grey
                            : (_showGrid ? Colors.greenAccent : Colors.white70),
                        size: 24,
                      ),
                    ),
                  ),
                  // Logout button
                  GestureDetector(
                    onTap: _isProcessing ? null : _confirmLogout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Icon(
                        Icons.logout,
                        color: _isProcessing ? Colors.grey : Colors.greenAccent,
                        size: 24,
                      ),
                    ),
                  ),
                  // Switch camera button
                  GestureDetector(
                    onTap: _isProcessing ? null : _switchCamera,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Icon(
                        Icons.cameraswitch,
                        color: _isProcessing ? Colors.grey : Colors.greenAccent,
                        size: 24,
                      ),
                    ),
                  ),
                  // History button
                  GestureDetector(
                    onTap: _isProcessing
                        ? null
                        : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HistoryScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Icon(
                        Icons.history,
                        color: _isProcessing ? Colors.grey : Colors.greenAccent,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                width: double.infinity,
                color: Colors.black, // ← long black background
                child: Center(
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _captureAndSend,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isProcessing ? Colors.grey : Colors.greenAccent,
                          width: 4,
                        ),
                      ),
                      child: _isProcessing
                          ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                          strokeWidth: 2,
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),


          // Zoom slider
          Positioned(
            bottom: 120,
            left: 40,
            right: 40,
            child: Slider(
              value: _currentZoom,
              min: _minZoom,
              max: _maxZoom,
              activeColor: Colors.greenAccent,
              inactiveColor: Colors.greenAccent.withOpacity(0.3),
              onChanged: _isProcessing ? null : (value) => _setZoom(value),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              width: double.infinity,
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ------------------ UPLOAD BUTTON (LEFT SIDE) ------------------
                  GestureDetector(
                    onTap: _isProcessing ? null : _uploadFromGallery,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent, width: 3),
                      ),
                      child: const Icon(Icons.upload, color: Colors.greenAccent, size: 30),
                    ),
                  ),

                  // ------------------ CAPTURE BUTTON (CENTER) ------------------
                  GestureDetector(
                    onTap: _isProcessing ? null : _captureAndSend,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isProcessing ? Colors.grey : Colors.greenAccent,
                          width: 4,
                        ),
                      ),
                      child: _isProcessing
                          ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                          strokeWidth: 2,
                        ),
                      )
                          : null,
                    ),
                  ),

                  // Empty space so layout stays symmetric
                  SizedBox(width: 60),
                ],
              ),
            ),
          )

        ],
      ),
    );
  }

  Future<void> _captureAndSend() async {
    if (!_controller!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Capture image with highest quality
      final file = await _controller!.takePicture();

      // Send to backend and get prediction
      final result = await _sendImageToBackend(file.path);

      setState(() => _isProcessing = false);

      // Show prediction dialog with the result
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => PredictionDialog(
            predictedClass: result['predictedClass'] as String,
            originalBase64: result['originalBase64'] as String,
            fakeThermalBase64: result['fakeThermalBase64'] as String,
            croppedVisBase64: result['croppedVisBase64'] as String,
            overlayBase64: result['overlayBase64'],
            onSave: () => _saveToFirebase(
              result['imagePath'] ?? file.path,
              result['predictedClass'] ?? 'Unknown',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _uploadFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      setState(() => _isProcessing = true);

      final result = await _sendImageToBackend(pickedFile.path);

      setState(() => _isProcessing = false);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => PredictionDialog(
            predictedClass: result['predictedClass'] as String,
            originalBase64: result['originalBase64'] as String,
            fakeThermalBase64: result['fakeThermalBase64'] as String,
            croppedVisBase64: result['croppedVisBase64'] as String,
            overlayBase64: result['overlayBase64'] as String,
            onSave: () => _saveToFirebase(
              result['imagePath'] ?? pickedFile.path,
              result['predictedClass'] ?? 'Unknown',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _sendImageToBackend(String path) async {
    try {
      // final uri = Uri.parse("http://192.168.1.65:8000/predict-gas");
      final url = dotenv.env['BACKEND_URL'];
      if (url == null) {
        throw Exception("BACKEND_URL not found in .env file");
      }

      final uri = Uri.parse(url);
      final request = http.MultipartRequest("POST", uri);

      final extension = path.split('.').last.toLowerCase();
      String contentType = extension == 'png' ? 'image/png' : 'image/jpeg';

      final mimeType = contentType.split('/');
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        path,
        filename: 'image.$extension',
        contentType: http.MediaType(mimeType[0], mimeType[1]),
      ));

      // Read the original image file and convert to base64
      final imageBytes = await File(path).readAsBytes();
      final originalBase64 = base64Encode(imageBytes);

      final response = await request.send().timeout(const Duration(seconds: 30));

      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseBody) as Map<String, dynamic>;

        return {
          'predictedClass': jsonData['predicted_class'] ?? 'Unknown',
          'originalBase64': originalBase64, // Original image from camera/gallery
          'fakeThermalBase64': jsonData['fake_thermal'] ?? '',
          'croppedVisBase64': jsonData['cropped_vis'] ?? '',
          'overlayBase64': jsonData['overlay'] ?? '',
        };
      } else {
        throw Exception("Server error: $responseBody");
      }
    } on SocketException {
      throw Exception("Backend unreachable. Is the server running?");
    } on TimeoutException {
      throw Exception("Request timed out");
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }
  Future<void> _saveToFirebase(String imagePath, String predictedClass) async {
    try {
      // Read userId (consistent key)
      final secureStorage = FlutterSecureStorage();
      final userId = await secureStorage.read(key: 'userId') ?? "unknown";

      // COMPRESS IMAGE BEFORE BASE64 (important)
      final compressed = await FlutterImageCompress.compressWithFile(
        imagePath,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
      );

      if (compressed == null) {
        throw Exception("Image compression failed");
      }

      final base64Image = base64Encode(compressed);

      // Save to Firestore
      await FirebaseFirestore.instance.collection('predictions').add({
        'userId': userId,
        'image': base64Image,
        'prediction': predictedClass,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to History'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // closes dialog
      }
    } catch (e) {
      print("Error saving: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Save Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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

// Grid Painter for camera grid overlay
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw vertical lines (divide into thirds)
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    // Draw horizontal lines (divide into thirds)
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}


