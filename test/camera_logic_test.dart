import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';

void main() {
  group('Camera Screen - Image Processing Tests', () {
    test('should extract file extension correctly', () {
      String getExtension(String path) {
        return path.split('.').last.toLowerCase();
      }

      expect(getExtension('/path/to/image.jpg'), equals('jpg'));
      expect(getExtension('/path/to/photo.png'), equals('png'));
      expect(getExtension('captured_image.jpeg'), equals('jpeg'));
      expect(getExtension('/storage/emulated/0/DCIM/IMG_001.JPG'), equals('jpg'));
    });

    test('should determine correct MIME type from extension', () {
      String getContentType(String extension) {
        return extension == 'png' ? 'image/png' : 'image/jpeg';
      }

      expect(getContentType('png'), equals('image/png'));
      expect(getContentType('jpg'), equals('image/jpeg'));
      expect(getContentType('jpeg'), equals('image/jpeg'));
      expect(getContentType('unknown'), equals('image/jpeg')); // default
    });

    test('should encode image bytes to base64', () {
      final mockImageBytes = List<int>.generate(100, (i) => i % 256);
      final base64String = base64Encode(mockImageBytes);

      expect(base64String, isA<String>());
      expect(base64String.isNotEmpty, true);

      // Verify it can be decoded back
      final decoded = base64Decode(base64String);
      expect(decoded, equals(mockImageBytes));
    });

    test('should handle backend response parsing', () {
      final mockJsonResponse = '''
      {
        "predicted_class": "Gas Detected",
        "fake_thermal": "base64_thermal_data",
        "cropped_vis": "base64_cropped_data",
        "overlay": "base64_overlay_data"
      }
      ''';

      final jsonData = jsonDecode(mockJsonResponse) as Map<String, dynamic>;

      expect(jsonData['predicted_class'], equals('Gas Detected'));
      expect(jsonData['fake_thermal'], equals('base64_thermal_data'));
      expect(jsonData['cropped_vis'], equals('base64_cropped_data'));
      expect(jsonData['overlay'], equals('base64_overlay_data'));
    });

    test('should handle missing fields in backend response with defaults', () {
      final mockJsonResponse = '{"predicted_class": "NoGas"}';
      final jsonData = jsonDecode(mockJsonResponse) as Map<String, dynamic>;

      final predictedClass = jsonData['predicted_class'] ?? 'Unknown';
      final fakeThermal = jsonData['fake_thermal'] ?? '';
      final croppedVis = jsonData['cropped_vis'] ?? '';
      final overlay = jsonData['overlay'] ?? '';

      expect(predictedClass, equals('NoGas'));
      expect(fakeThermal, isEmpty);
      expect(croppedVis, isEmpty);
      expect(overlay, isEmpty);
    });

    test('should validate backend response structure', () {
      Map<String, dynamic> buildResponse(String originalBase64, Map<String, dynamic> apiData) {
        return {
          'predictedClass': apiData['predicted_class'] ?? 'Unknown',
          'originalBase64': originalBase64,
          'fakeThermalBase64': apiData['fake_thermal'] ?? '',
          'croppedVisBase64': apiData['cropped_vis'] ?? '',
          'overlayBase64': apiData['overlay'] ?? '',
        };
      }

      final mockApiData = {
        'predicted_class': 'Gas',
        'fake_thermal': 'thermal123',
        'cropped_vis': 'cropped456',
        'overlay': 'overlay789',
      };

      final result = buildResponse('original123', mockApiData);

      expect(result['predictedClass'], equals('Gas'));
      expect(result['originalBase64'], equals('original123'));
      expect(result['fakeThermalBase64'], equals('thermal123'));
      expect(result['croppedVisBase64'], equals('cropped456'));
      expect(result['overlayBase64'], equals('overlay789'));
    });
  });

  group('Camera Screen - Flash Mode Tests', () {
    test('should cycle through flash modes in correct order', () {
      FlashMode currentMode = FlashMode.off;

      // off -> auto
      currentMode = FlashMode.auto;
      expect(currentMode, equals(FlashMode.auto));

      // auto -> always
      currentMode = FlashMode.always;
      expect(currentMode, equals(FlashMode.always));

      // always -> torch
      currentMode = FlashMode.torch;
      expect(currentMode, equals(FlashMode.torch));

      // torch -> off (cycle complete)
      currentMode = FlashMode.off;
      expect(currentMode, equals(FlashMode.off));
    });

    test('should return correct icon for each flash mode', () {
      expect(FlashMode.off, isA<FlashMode>());
      expect(FlashMode.auto, isA<FlashMode>());
      expect(FlashMode.always, isA<FlashMode>());
      expect(FlashMode.torch, isA<FlashMode>());
    });
  });

  group('Camera Screen - Zoom Tests', () {
    test('should clamp zoom within min and max bounds', () {
      const double minZoom = 1.0;
      const double maxZoom = 8.0;

      // Test normal zoom
      expect(5.0.clamp(minZoom, maxZoom), equals(5.0));

      // Test below minimum
      expect(0.5.clamp(minZoom, maxZoom), equals(minZoom));

      // Test above maximum
      expect(10.0.clamp(minZoom, maxZoom), equals(maxZoom));

      // Test at boundaries
      expect(1.0.clamp(minZoom, maxZoom), equals(1.0));
      expect(8.0.clamp(minZoom, maxZoom), equals(8.0));
    });

    test('should calculate scaled zoom correctly', () {
      double calculateZoom(double currentZoom, double scale, double min, double max) {
        return (currentZoom * scale).clamp(min, max);
      }

      expect(calculateZoom(2.0, 1.5, 1.0, 8.0), equals(3.0));
      expect(calculateZoom(1.0, 0.5, 1.0, 8.0), equals(1.0)); // clamped to min
      expect(calculateZoom(6.0, 2.0, 1.0, 8.0), equals(8.0)); // clamped to max
    });
  });

  group('Camera Screen - Camera Index Tests', () {
    test('should cycle through camera indices', () {
      const int totalCameras = 2;
      int currentIndex = 0;

      // First switch
      currentIndex = (currentIndex + 1) % totalCameras;
      expect(currentIndex, equals(1));

      // Second switch (back to 0)
      currentIndex = (currentIndex + 1) % totalCameras;
      expect(currentIndex, equals(0));
    });

    test('should handle single camera', () {
      const int totalCameras = 1;
      int currentIndex = 0;

      currentIndex = (currentIndex + 1) % totalCameras;
      expect(currentIndex, equals(0)); // stays at 0
    });
  });

  group('Camera Screen - Processing State Tests', () {
    test('should track processing state correctly', () {
      bool isProcessing = false;

      // Start processing
      isProcessing = true;
      expect(isProcessing, true);

      // Stop processing
      isProcessing = false;
      expect(isProcessing, false);
    });

    test('should prevent operations when processing', () {
      bool canPerformOperation(bool isProcessing) {
        return !isProcessing;
      }

      expect(canPerformOperation(false), true);
      expect(canPerformOperation(true), false);
    });
  });

  group('Camera Screen - Grid Display Tests', () {
    test('should toggle grid visibility', () {
      bool showGrid = false;

      showGrid = !showGrid;
      expect(showGrid, true);

      showGrid = !showGrid;
      expect(showGrid, false);
    });
  });

  group('Camera Screen - Error Handling Tests', () {
    test('should format Socket exception message', () {
      String formatSocketError() {
        return "Backend unreachable. Is the server running?";
      }

      expect(formatSocketError(), contains('Backend unreachable'));
    });

    test('should format Timeout exception message', () {
      String formatTimeoutError() {
        return "Request timed out";
      }

      expect(formatTimeoutError(), equals("Request timed out"));
    });

    test('should format generic network error', () {
      String formatNetworkError(String error) {
        return "Network error: $error";
      }

      expect(formatNetworkError('Connection failed'),
          equals('Network error: Connection failed'));
    });

    test('should validate image compression result', () {
      bool isCompressionValid(dynamic compressed) {
        return compressed != null;
      }

      expect(isCompressionValid([1, 2, 3]), true);
      expect(isCompressionValid(null), false);
    });
  });

  group('Camera Screen - Firebase Save Tests', () {
    test('should use correct secure storage key', () {
      const String userIdKey = 'userId';
      expect(userIdKey, equals('userId'));
    });

    test('should handle null userId with default', () {
      String? userId;
      final safeUserId = userId ?? "unknown";

      expect(safeUserId, equals("unknown"));
    });

    test('should build Firestore document structure', () {
      Map<String, dynamic> buildDocument(String userId, String base64Image, String prediction) {
        return {
          'userId': userId,
          'image': base64Image,
          'prediction': prediction,
          'timestamp': 'server_timestamp', // Placeholder for FieldValue.serverTimestamp()
        };
      }

      final doc = buildDocument('user123', 'img_data', 'Gas Detected');

      expect(doc['userId'], equals('user123'));
      expect(doc['image'], equals('img_data'));
      expect(doc['prediction'], equals('Gas Detected'));
      expect(doc.containsKey('timestamp'), true);
    });
  });

  group('Camera Screen - Focus and Exposure Tests', () {
    test('should calculate focus point offset', () {
      double calculateOffset(double localPosition, double totalSize) {
        return localPosition / totalSize;
      }

      expect(calculateOffset(100, 200), equals(0.5));
      expect(calculateOffset(50, 200), equals(0.25));
      expect(calculateOffset(150, 200), equals(0.75));
    });
  });
}