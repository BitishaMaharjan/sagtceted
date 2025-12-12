import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;

class PredictionDialog extends StatefulWidget {
  final String predictedClass;
  final String originalBase64;
  final String fakeThermalBase64;
  final String croppedVisBase64;
  final String overlayBase64;
  final VoidCallback? onSave;

  const PredictionDialog({
    Key? key,
    required this.predictedClass,
    required this.originalBase64,
    required this.fakeThermalBase64,
    required this.croppedVisBase64,
    required this.overlayBase64,
    this.onSave,
  }) : super(key: key);

  @override
  State<PredictionDialog> createState() => _PredictionDialogState();
}

class _PredictionDialogState extends State<PredictionDialog> {
  Uint8List? _overlayImageBytes;

  @override
  void initState() {
    super.initState();
    _createOverlayImage();
  }

  Future<void> _createOverlayImage() async {
    try {
      // Decode base64 strings
      final originalBytes = _decodeBase64(widget.originalBase64);
      final croppedBytes = _decodeBase64(widget.croppedVisBase64);

      // Check if predicted class is "NoGas" or if cropped image is fully black
      if (widget.predictedClass.toLowerCase() == 'Nogas' ||
          widget.predictedClass.toLowerCase() == 'no gas' ||
          _isImageFullyBlack(croppedBytes)) {
        // Use original image instead of overlay
        if (mounted) {
          setState(() {
            _overlayImageBytes = originalBytes;
          });
        }
        return;
      }

      // Load images
      final originalImage = await _loadImage(originalBytes);
      final croppedImage = await _loadImage(croppedBytes);

      // Create overlay
      final overlayBytes = await _overlayImages(originalImage, croppedImage);

      if (mounted) {
        setState(() {
          _overlayImageBytes = overlayBytes;
        });
      }
    } catch (e) {
      print('Error creating overlay: $e');
      // Fallback to original image on error
      try {
        final originalBytes = _decodeBase64(widget.originalBase64);
        if (mounted) {
          setState(() {
            _overlayImageBytes = originalBytes;
          });
        }
      } catch (e) {
        print('Error loading original image: $e');
      }
    }
  }

  bool _isImageFullyBlack(Uint8List imageBytes) {
    // Sample pixels to check if image is fully black
    // Check first 100 pixels (or less if image is smaller)
    int samplesToCheck = imageBytes.length < 300 ? imageBytes.length ~/ 3 : 100;

    for (int i = 0; i < samplesToCheck * 3 && i < imageBytes.length - 2; i += 3) {
      // Check RGB values (skip alpha channel)
      if (imageBytes[i] > 10 || imageBytes[i + 1] > 10 || imageBytes[i + 2] > 10) {
        return false; // Found a non-black pixel
      }
    }
    return true; // Image is fully black
  }

  Uint8List _decodeBase64(String base64String) {
    final cleanBase64 = base64String.contains(',')
        ? base64String.split(',').last
        : base64String;
    return base64Decode(cleanBase64);
  }

  Future<ui.Image> _loadImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Uint8List> _overlayImages(ui.Image original, ui.Image cropped) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw original image
    canvas.drawImage(original, Offset.zero, Paint());

    // Calculate position to center the cropped image
    final xOffset = (original.width - cropped.width) / 2;
    final yOffset = (original.height - cropped.height) / 2;

    // Draw the cropped image directly on top (no dark overlay, just show the crop)
    final croppedPaint = Paint();
    canvas.drawImageRect(
      cropped,
      Rect.fromLTWH(0, 0, cropped.width.toDouble(), cropped.height.toDouble()),
      Rect.fromLTWH(xOffset, yOffset, cropped.width.toDouble(), cropped.height.toDouble()),
      croppedPaint,
    );

    // Draw border around cropped area for visibility
    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(
      Rect.fromLTWH(xOffset, yOffset, cropped.width.toDouble(), cropped.height.toDouble()),
      borderPaint,
    );

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(original.width, original.height);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Prediction Result',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // 2x2 Grid of Images
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Row 1: Original + Fake Thermal
                      Row(
                        children: [
                          _buildImageFromBase64(widget.originalBase64, 'Original'),
                          const SizedBox(width: 8),
                          _buildImageFromBase64(widget.fakeThermalBase64, 'Fake Thermal'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Row 2: Cropped Visual + Overlay
                      Row(
                        children: [
                          _buildImageFromBase64(widget.croppedVisBase64, 'Cropped Visual'),
                          const SizedBox(width: 8),
                          _buildOverlayImage(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Prediction Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.greenAccent, width: 1.5),
                  ),
                  child: Text(
                    widget.predictedClass,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white70, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    if (widget.onSave != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: widget.onSave,
                          child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayImage() {
    if (_overlayImageBytes == null) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
                color: Colors.grey[900],
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.greenAccent,
                  strokeWidth: 2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Overlay',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _overlayImageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Overlay',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String base64String, String label) {
    try {
      // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
      final cleanBase64 = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;

      final bytes = base64Decode(cleanBase64);

      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } catch (e) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
                color: Colors.grey[900],
              ),
              child: const Center(
                child: Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}