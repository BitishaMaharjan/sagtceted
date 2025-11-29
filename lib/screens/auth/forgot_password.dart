import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
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

  Future<void> sendReset() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _show("Please enter your email");
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _show("Reset link sent!");
      Navigator.pop(context);
    } catch (e) {
      _show("Error: $e");
    }

    setState(() => loading = false);
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND
          Positioned.fill(
            child: AnimatedContainer(
              duration: Duration(seconds: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.green.withOpacity(0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          /// Glow circles (top)
          Positioned(
            top: -40,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.15),
              ),
            ),
          ),

          /// Glow circles (bottom)
          Positioned(
            bottom: -50,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ),

          /// CONTENT
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.lock_reset,
                      size: 90, color: Colors.greenAccent),
                  SizedBox(height: 20),

                  Text(
                    "Reset Password",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 20),

                  Text(
                    "Enter your email and we will send you a password reset link.",
                    style: TextStyle(
                      color: Colors.greenAccent.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 30),

                  /// Email field
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInput("Email"),
                  ),

                  SizedBox(height: 30),

                  /// Send Reset Button
                  GestureDetector(
                    onTap: sendReset,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.greenAccent.withOpacity(.2),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Center(
                        child: loading
                            ? CircularProgressIndicator(color: Colors.greenAccent)
                            : Text(
                          "SEND RESET LINK",
                          style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 18),

                  /// Back to login
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "Back to Login",
                      style: TextStyle(
                          color: Colors.greenAccent.withOpacity(0.9),
                          fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
