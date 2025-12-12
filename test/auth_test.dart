// test/auth_pages_coverage_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sagtceted/screens/auth/forgot_password.dart';
import 'package:sagtceted/screens/auth/login_page.dart';
import 'package:sagtceted/screens/auth/register_page.dart';


// --- Mock classes ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUserCredential extends Mock implements UserCredential {}
class MockUser extends Mock implements User {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForgotPasswordPage Tests', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth();
    });

    testWidgets('renders all widgets', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('SEND RESET LINK'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('shows error when email empty', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));

      await tester.tap(find.text('SEND RESET LINK'));
      await tester.pump(); // SnackBar appears
      expect(find.text('Please enter your email'), findsOneWidget);
    });
  });

  group('LoginPage Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUserCredential mockUserCred;
    late MockUser mockUser;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUserCred = MockUserCredential();
      mockUser = MockUser();
      mockStorage = MockSecureStorage();
    });

    testWidgets('renders LoginPage widgets', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text("Forgot Password?"), findsOneWidget);
      expect(find.text("Didn't have a Account ? Register "), findsOneWidget);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      final icon = find.byIcon(Icons.visibility_off);
      await tester.tap(icon);
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  group('RegisterPage Tests', () {
    testWidgets('renders RegisterPage widgets', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RegisterPage()));

      expect(find.text('REGISTER'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('shows error for empty fields', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RegisterPage()));

      await tester.tap(find.text('REGISTER'));
      await tester.pump(); // SnackBar appears
      expect(find.text('Please fill all fields'), findsOneWidget);
    });

    testWidgets('shows error for mismatched passwords', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RegisterPage()));

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.tap(find.text('REGISTER'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('shows error for short password', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RegisterPage()));

      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123');
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.tap(find.text('REGISTER'));
      await tester.pump();

      expect(find.text('Password should be at least 6 characters'), findsOneWidget);
    });
  });
}
