import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../components/gas_bubble_background.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confController.dispose();
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

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();
    final conf = confController.text.trim();

    if (email.isEmpty || pass.isEmpty || conf.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }
    if (pass != conf) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Passwords do not match")));
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password should be at least 6 characters")));
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Account created successfully!")));

      // Optionally navigate back to login page:
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? "Registration failed";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // keep AppBar minimal; login had none — this matches the login style
      body: Stack(
        children: [
          Positioned.fill(child: GasBubbleBackground()),


          Container(
            color: Colors.black.withOpacity(0.45),
          ),

          // Main content (mirrors Login)
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.air_rounded, size: 60, color: Colors.greenAccent),
                      SizedBox(width: 12),
                      Text(
                        "SAGTCETED", // Uppercase for sci-fi effect
                        style: TextStyle(
                          fontFamily: 'monospace', // Built-in font
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                          letterSpacing: 2, // Wider spacing for futuristic look
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
                        angle: 3.1416, // Rotate icon to face left
                        child: Icon(Icons.air_rounded, size: 60, color: Colors.greenAccent),
                      ),

                    ],
                  ),
                  SizedBox(height: 30),

                  // Email
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _buildInput("Email"),
                  ),
                  SizedBox(height: 26),

                  // Password
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _buildInput("Password"),
                  ),
                  SizedBox(height: 16),

                  // Confirm Password
                  TextField(
                    controller: confController,
                    obscureText: true,
                    decoration: _buildInput("Confirm Password"),
                  ),
                  SizedBox(height: 32),

                  // Register button (matches login style)
                  GestureDetector(
                    onTap: registerUser,
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
                            : Text("REGISTER",
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),

                  SizedBox(height: 18),

                  // Back to Login link (same accent)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text("Back to Login",
                        style: TextStyle(
                            color: Colors.greenAccent.withOpacity(0.9))),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
