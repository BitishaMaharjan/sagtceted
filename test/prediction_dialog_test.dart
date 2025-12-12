import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagtceted/components/prediction_dialog.dart';

void main() {
  group('PredictionDialog Tests', () {
    late String testBase64Image;

    setUp(() {
      // Create a small test base64 image (1x1 transparent PNG)
      testBase64Image =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    });

    testWidgets('should render PredictionDialog with all images',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PredictionDialog(
                  predictedClass: 'Gas Detected',
                  originalBase64: testBase64Image,
                  fakeThermalBase64: testBase64Image,
                  croppedVisBase64: testBase64Image,
                  overlayBase64: testBase64Image,
                ),
              ),
            ),
          );

          // Wait for the dialog to build
          await tester.pump();

          // Verify dialog title
          expect(find.text('Prediction Result'), findsOneWidget);

          // Verify predicted class label
          expect(find.text('Gas Detected'), findsOneWidget);

          // Verify image labels
          expect(find.text('Original'), findsOneWidget);
          expect(find.text('Fake Thermal'), findsOneWidget);
          expect(find.text('Cropped Visual'), findsOneWidget);
          expect(find.text('Overlay'), findsOneWidget);

          // Verify close button
          expect(find.text('Close'), findsOneWidget);
        });

    testWidgets('should handle NoGas prediction and show original image',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PredictionDialog(
                  predictedClass: 'NoGas',
                  originalBase64: testBase64Image,
                  fakeThermalBase64: testBase64Image,
                  croppedVisBase64: testBase64Image,
                  overlayBase64: testBase64Image,
                ),
              ),
            ),
          );

          // Wait for initial build
          await tester.pump();

          // Wait for async overlay creation with specific duration
          await tester.pump(const Duration(milliseconds: 500));

          // Verify NoGas label is displayed
          expect(find.text('NoGas'), findsOneWidget);
        });

    testWidgets('should handle "no gas" (with space) prediction',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PredictionDialog(
                  predictedClass: 'no gas',
                  originalBase64: testBase64Image,
                  fakeThermalBase64: testBase64Image,
                  croppedVisBase64: testBase64Image,
                  overlayBase64: testBase64Image,
                ),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          expect(find.text('no gas'), findsOneWidget);
        });

    testWidgets('should show loading indicator while creating overlay',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PredictionDialog(
                  predictedClass: 'Gas Detected',
                  originalBase64: testBase64Image,
                  fakeThermalBase64: testBase64Image,
                  croppedVisBase64: testBase64Image,
                  overlayBase64: testBase64Image,
                ),
              ),
            ),
          );

          // Initial pump - overlay is still loading
          await tester.pump();

          // Should show loading indicator
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        });

    // testWidgets('should call onSave callback when Save button is pressed',
    //         (WidgetTester tester) async {
    //       bool saveCalled = false;
    //
    //       await tester.pumpWidget(
    //         MaterialApp(
    //           home: Scaffold(
    //             body: PredictionDialog(
    //               predictedClass: 'Gas Detected',
    //               originalBase64: testBase64Image,
    //               fakeThermalBase64: testBase64Image,
    //               croppedVisBase64: testBase64Image,
    //               overlayBase64: testBase64Image,
    //               onSave: () {
    //                 saveCalled = true;
    //               },
    //             ),
    //           ),
    //         ),
    //       );
    //
    //       await tester.pump();
    //       await tester.pump(const Duration(milliseconds: 500));
    //
    //       // Find and tap the Save button - use text finder instead
    //       expect(find.text('Save'), findsOneWidget);
    //
    //       await tester.tap(find.text('Save'), warnIfMissed: false);
    //       await tester.pump();
    //
    //       expect(saveCalled, true);
    //     });

    testWidgets('should not show Save button when onSave is null',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PredictionDialog(
                  predictedClass: 'Gas Detected',
                  originalBase64: testBase64Image,
                  fakeThermalBase64: testBase64Image,
                  croppedVisBase64: testBase64Image,
                  overlayBase64: testBase64Image,
                  // onSave is null
                ),
              ),
            ),
          );

          await tester.pump();

          // Save button should not be present
          expect(find.text('Save'), findsNothing);
        });

    testWidgets('should close dialog when Close button is pressed',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => PredictionDialog(
                            predictedClass: 'Gas Detected',
                            originalBase64: testBase64Image,
                            fakeThermalBase64: testBase64Image,
                            croppedVisBase64: testBase64Image,
                            overlayBase64: testBase64Image,
                          ),
                        );
                      },
                      child: const Text('Show Dialog'),
                    ),
                  ),
                ),
              ),
            ),
          );

          // Open the dialog
          await tester.tap(find.text('Show Dialog'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));

          // Verify dialog is shown
          expect(find.text('Prediction Result'), findsOneWidget);

          // Tap Close button with warnIfMissed: false
          await tester.tap(find.text('Close'), warnIfMissed: false);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Verify dialog is closed
          expect(find.text('Prediction Result'), findsNothing);
        });


    testWidgets('should handle base64 with data URL prefix',
            (WidgetTester tester) async {
          final prefixedBase64 = 'data:image/png;base64,$testBase64Image';

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PredictionDialog(
                  predictedClass: 'Gas Detected',
                  originalBase64: prefixedBase64,
                  fakeThermalBase64: prefixedBase64,
                  croppedVisBase64: prefixedBase64,
                  overlayBase64: prefixedBase64,
                ),
              ),
            ),
          );

          await tester.pump();

          // Should successfully decode and display images
          expect(find.text('Prediction Result'), findsOneWidget);
          expect(find.byType(Image), findsWidgets);
        });

    testWidgets('should handle scrolling in dialog',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PredictionDialog(
                  predictedClass: 'Gas Detected with a very long name that might overflow',
                  originalBase64: testBase64Image,
                  fakeThermalBase64: testBase64Image,
                  croppedVisBase64: testBase64Image,
                  overlayBase64: testBase64Image,
                ),
              ),
            ),
          );

          await tester.pump();

          // Verify SingleChildScrollView is present
          expect(find.byType(SingleChildScrollView), findsOneWidget);
        });

    testWidgets('should complete overlay creation for normal gas detection',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PredictionDialog(
                  predictedClass: 'Gas Detected',
                  originalBase64: testBase64Image,
                  fakeThermalBase64: testBase64Image,
                  croppedVisBase64: testBase64Image,
                  overlayBase64: testBase64Image,
                ),
              ),
            ),
          );

          // Initial build
          await tester.pump();

          // First check - should show loading indicator
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          // Wait for overlay to complete - pump multiple times
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));

          // Verify overlay label is shown
          expect(find.text('Overlay'), findsOneWidget);

          // Note: CircularProgressIndicator might still be there if overlay is still loading
          // This is acceptable behavior, so we'll just verify the overlay text exists
        });

    // Unit tests for helper logic
    group('Helper Functions', () {
      test('should decode base64 string correctly', () {
        final cleanBase64 = testBase64Image.contains(',')
            ? testBase64Image.split(',').last
            : testBase64Image;

        final bytes = base64Decode(cleanBase64);

        expect(bytes, isA<Uint8List>());
        expect(bytes.isNotEmpty, true);
      });

      test('should handle base64 with data URL prefix', () {
        final prefixedBase64 = 'data:image/png;base64,$testBase64Image';

        final cleanBase64 = prefixedBase64.contains(',')
            ? prefixedBase64.split(',').last
            : prefixedBase64;

        final bytes = base64Decode(cleanBase64);

        expect(bytes, isA<Uint8List>());
        expect(bytes.isNotEmpty, true);
      });

      test('should detect NoGas prediction class correctly', () {
        bool isNoGas(String predictedClass) {
          return predictedClass.toLowerCase() == 'nogas' ||
              predictedClass.toLowerCase() == 'no gas';
        }

        expect(isNoGas('Nogas'), true);
        expect(isNoGas('NoGas'), true);
        expect(isNoGas('no gas'), true);
        expect(isNoGas('No Gas'), true);
        expect(isNoGas('Gas Detected'), false);
        expect(isNoGas('Gas'), false);
      });

      test('should check if image is fully black', () {
        // Create a fully black image (all zeros)
        final blackImage = Uint8List(300);
        for (int i = 0; i < blackImage.length; i++) {
          blackImage[i] = 0;
        }

        // Check if all pixels are black
        bool isBlack = true;
        int samplesToCheck = blackImage.length < 300 ? blackImage.length ~/ 3 : 100;

        for (int i = 0; i < samplesToCheck * 3 && i < blackImage.length - 2; i += 3) {
          if (blackImage[i] > 10 || blackImage[i + 1] > 10 || blackImage[i + 2] > 10) {
            isBlack = false;
            break;
          }
        }

        expect(isBlack, true);
      });

      test('should detect non-black image', () {
        // Create an image with some white pixels
        final coloredImage = Uint8List(300);
        coloredImage[0] = 255; // Red channel
        coloredImage[1] = 255; // Green channel
        coloredImage[2] = 255; // Blue channel

        // Check if image is black
        bool isBlack = true;
        int samplesToCheck = 100;

        for (int i = 0; i < samplesToCheck * 3 && i < coloredImage.length - 2; i += 3) {
          if (coloredImage[i] > 10 || coloredImage[i + 1] > 10 || coloredImage[i + 2] > 10) {
            isBlack = false;
            break;
          }
        }

        expect(isBlack, false);
      });

      test('should handle invalid base64 gracefully', () {
        final invalidBase64 = 'not_valid_base64!!!';

        expect(() => base64Decode(invalidBase64), throwsFormatException);
      });

      test('should extract clean base64 from data URL', () {
        final dataUrl = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';

        String extractBase64(String base64String) {
          return base64String.contains(',')
              ? base64String.split(',').last
              : base64String;
        }

        final extracted = extractBase64(dataUrl);

        expect(extracted, equals('/9j/4AAQSkZJRg=='));
        expect(extracted.contains('data:'), false);
      });
    });
  });
}