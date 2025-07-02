import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bulk Import Validation Tests', () {
    test('Should validate phone numbers correctly', () {
      // Test valid phone numbers
      expect(_isValidPhone('081234567890'), isTrue);
      expect(_isValidPhone('087654321098'), isTrue);
      expect(_isValidPhone('0812345678'), isTrue); // 10 digits
      expect(_isValidPhone('08123456789012'), isTrue); // 13 digits

      // Test invalid phone numbers
      expect(_isValidPhone('123456789'), isFalse); // too short
      expect(_isValidPhone('081234567890123'), isFalse); // too long
      expect(_isValidPhone('08abc1234567'), isFalse); // contains letters
      expect(_isValidPhone(''), isFalse); // empty
    });

    test('Should validate required fields', () {
      expect(_isValidName('John Doe'), isTrue);
      expect(_isValidName(''), isFalse);
      expect(_isValidName('   '), isFalse);

      expect(_isValidAddress('Jl. Test No. 123'), isTrue);
      expect(_isValidAddress(''), isFalse);
      expect(_isValidAddress('   '), isFalse);
    });

    test('Should clean phone number correctly', () {
      expect(_cleanPhone('081-234-567-890'), equals('081234567890'));
      expect(_cleanPhone('081 234 567 890'), equals('081234567890'));
      expect(_cleanPhone('(081) 234-567-890'), equals('081234567890'));
      expect(_cleanPhone('081234567890'), equals('081234567890'));
    });

    test('Should validate student data map', () {
      final validData = {
        'name': 'John Doe',
        'address': 'Jl. Test No. 123',
        'phone': '081234567890',
      };
      expect(_isValidStudentData(validData), isTrue);

      final invalidDataEmptyName = {
        'name': '',
        'address': 'Jl. Test No. 123',
        'phone': '081234567890',
      };
      expect(_isValidStudentData(invalidDataEmptyName), isFalse);

      final invalidDataEmptyAddress = {
        'name': 'John Doe',
        'address': '',
        'phone': '081234567890',
      };
      expect(_isValidStudentData(invalidDataEmptyAddress), isFalse);

      final invalidDataEmptyPhone = {
        'name': 'John Doe',
        'address': 'Jl. Test No. 123',
        'phone': '',
      };
      expect(_isValidStudentData(invalidDataEmptyPhone), isFalse);

      final invalidDataBadPhone = {
        'name': 'John Doe',
        'address': 'Jl. Test No. 123',
        'phone': '123',
      };
      expect(_isValidStudentData(invalidDataBadPhone), isFalse);
    });
  });
}

// Helper validation functions (these mirror the logic in our app)
bool _isValidPhone(String phone) {
  if (phone.trim().isEmpty) return false;
  final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
  return cleanPhone.length >= 10 && cleanPhone.length <= 13;
}

bool _isValidName(String name) {
  return name.trim().isNotEmpty;
}

bool _isValidAddress(String address) {
  return address.trim().isNotEmpty;
}

String _cleanPhone(String phone) {
  return phone.replaceAll(RegExp(r'[^\d]'), '');
}

bool _isValidStudentData(Map<String, String> data) {
  return _isValidName(data['name'] ?? '') &&
      _isValidAddress(data['address'] ?? '') &&
      _isValidPhone(data['phone'] ?? '');
}
