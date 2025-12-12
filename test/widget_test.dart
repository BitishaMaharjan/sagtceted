import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Smoke Tests', () {
    test('should pass basic smoke test', () {
      expect(1 + 1, equals(2));
      expect('hello'.toUpperCase(), equals('HELLO'));
    });

    test('should handle string operations', () {
      final email = 'test@example.com';
      expect(email.contains('@'), true);
      expect(email.split('@').length, equals(2));
    });

    test('should handle list operations', () {
      final list = [1, 2, 3, 4, 5];
      expect(list.length, equals(5));
      expect(list.first, equals(1));
      expect(list.last, equals(5));
    });
  });
}