import 'package:flutter/material.dart';
import 'camera_screen.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CameraScreen(cameras: cameras); // Opens camera directly
  }
}
