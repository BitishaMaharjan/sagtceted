import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../home_screen.dart';
import '../../components/gas_bubble_background.dart';
import 'register_page.dart';
import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  final _secureStorage = const FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: GasBubbleBackground()),
          Container(color: Colors.black.withOpacity(0.45)),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.air_rounded, size: 80, color: Colors.greenAccent),
                      SizedBox(width: 12),
                      Text(
                        "SAGTCETED",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.greenAccent.withOpacity(0.6),
                              blurRadius: 6,
                              offset: Offset(0, 0),
                            ),
                            Shadow(
                              color: Colors.greenAccent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      Transform.rotate(
                        angle: 3.1416,
                        child: Icon(Icons.air_rounded, size: 70, color: Colors.greenAccent),
                      ),
                    ],
                  ),
                  SizedBox(height: 70),

                  TextField(
                    controller: emailController,
                    decoration: _buildInput("Email"),
                  ),
                  SizedBox(height: 30),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _buildInput("Password"),
                  ),
                  SizedBox(height: 25),

                  GestureDetector(
                    onTap: loginUser,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.greenAccent.withOpacity(.25),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Center(
                        child: loading
                            ? CircularProgressIndicator(color: Colors.greenAccent)
                            : Text(
                          "LOGIN",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                    ),
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.greenAccent.withOpacity(0.8),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  Divider(color: Colors.greenAccent.withOpacity(0.4)),
                  SizedBox(height: 20),

                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterPage()),
                    ),
                    child: Text(
                      "Create New Account",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.greenAccent),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.greenAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.lightGreenAccent),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showDialog("Error", "Please enter email & password", isError: true);
      return;
    }

    setState(() => loading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);

      // Save user ID securely
      final uid = userCredential.user?.uid;
      if (uid != null) {
        await _secureStorage.write(key: 'userId', value: uid);
        await _secureStorage.write(key: 'email', value: email);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showDialog("Error", e.message ?? "Login failed", isError: true);
    } catch (e) {
      _showDialog("Error", "Error: $e", isError: true);
    }

    setState(() => loading = false);
  }

  void _showDialog(String title, String message,
      {bool isError = false, VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          title,
          style: TextStyle(
              color: isError ? Colors.redAccent : Colors.greenAccent),
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
            child: Text(
              "OK",
              style: TextStyle(
                  color: isError ? Colors.redAccent : Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }
}
