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
  bool hidePassword = true;

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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 60),

                  _buildTextField(emailController, "Email", false),
                  const SizedBox(height: 20),

                  _buildTextField(passwordController, "Password", true),

                  _buildForgotPassword(),

                  const SizedBox(height: 5),
                  _buildLoginButton(),

                  const SizedBox(height: 40),
                  Divider(color: Colors.greenAccent.withOpacity(0.4)),
                  const SizedBox(height: 20),

                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.air_rounded, size: 50, color: Colors.greenAccent),
        const SizedBox(width: 12),
        Text(
          "SAGTCETED",
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.greenAccent,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.greenAccent.withOpacity(0.6),
                blurRadius: 6,
              ),
              Shadow(
                color: Colors.greenAccent.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        Transform.rotate(
          angle: 3.1416,
          child: Icon(Icons.air_rounded, size: 50, color: Colors.greenAccent),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? hidePassword : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.greenAccent),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.greenAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.lightGreenAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            hidePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.greenAccent,
          ),
          onPressed: () {
            setState(() {
              hidePassword = !hidePassword;
            });
          },
        )
            : null,
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Container(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
          );
        },
        child: Text(
          "Forgot Password?",
          style: TextStyle(
            color: Colors.greenAccent.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: loginUser,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.greenAccent.withOpacity(0.25),
          border: Border.all(color: Colors.greenAccent),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.greenAccent)
              : const Text(
            "LOGIN",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RegisterPage()),
        );
      },
      child: Text(
        "Didn't have a Account ? Register ",
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
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
          style:
          TextStyle(color: isError ? Colors.redAccent : Colors.greenAccent),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
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
