import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Guardian Edit Validation Tests', () {
    test('Guardian edit data validation', () {
      final validData = {
        'name': 'John Doe Updated',
        'address': 'New Address 123',
        'phone': '08123456789',
      };

      expect(_isValidEditData(validData), true);

      final invalidNameData = {
        'name': '',
        'address': 'New Address 123',
        'phone': '08123456789',
      };
      expect(_isValidEditData(invalidNameData), false);

      final invalidPhoneData = {
        'name': 'John Doe',
        'address': 'New Address 123',
        'phone': '123', // Too short
      };
      expect(_isValidEditData(invalidPhoneData), false);
    });

    test('Guardian edit form initial values', () {
      final guardian = _createMockGuardian();
      final initialValues = _getInitialFormValues(guardian);

      expect(initialValues['name'], equals('Original Name'));
      expect(initialValues['address'], equals('Original Address'));
      expect(initialValues['phone'], equals('08123456789'));
    });

    test('Guardian edit success message formatting', () {
      const expectedMessage = 'Data wali berhasil diperbarui';

      expect(_formatEditSuccessMessage(), equals(expectedMessage));
    });

    test('Guardian edit error message formatting', () {
      const errorMessage = 'Database connection failed';
      const formattedError =
          'Gagal memperbarui data wali: Database connection failed';

      expect(_formatEditError(errorMessage), equals(formattedError));
      expect(_formatEditError(''), equals('Gagal memperbarui data wali: '));
    });
  });

  group('Guardian Edit Business Logic Tests', () {
    test('Should allow edit when data is different', () {
      final originalData = {
        'name': 'Original Name',
        'address': 'Original Address',
        'phone': '08123456789',
      };

      final newData = {
        'name': 'Updated Name',
        'address': 'Original Address',
        'phone': '08123456789',
      };

      expect(_hasChanges(originalData, newData), true);
    });

    test('Should detect no changes when data is same', () {
      final originalData = {
        'name': 'Same Name',
        'address': 'Same Address',
        'phone': '08123456789',
      };

      final sameData = {
        'name': 'Same Name',
        'address': 'Same Address',
        'phone': '08123456789',
      };

      expect(_hasChanges(originalData, sameData), false);
    });

    test('Should validate phone number format for edit', () {
      expect(_isValidPhoneForEdit('08123456789'), true);
      expect(_isValidPhoneForEdit('081234567890'), true);
      expect(_isValidPhoneForEdit('0812345678901'), true);
      expect(_isValidPhoneForEdit('123456789'), false); // Too short
      expect(_isValidPhoneForEdit('08123456789012'), false); // Too long
      expect(_isValidPhoneForEdit('abcd1234567'), false); // Contains letters
    });

    test('Should validate name format for edit', () {
      expect(_isValidNameForEdit('John Doe'), true);
      expect(_isValidNameForEdit('Jane Smith Updated'), true);
      expect(_isValidNameForEdit('A'), false); // Too short
      expect(_isValidNameForEdit(''), false); // Empty
      expect(_isValidNameForEdit('   '), false); // Only spaces
    });
  });
}

// Helper validation functions for testing
bool _isValidEditData(Map<String, String> data) {
  if (data['name'] == null || data['name']!.trim().isEmpty) return false;
  if (data['address'] == null || data['address']!.trim().isEmpty) return false;
  if (data['phone'] == null || data['phone']!.trim().isEmpty) return false;
  if (data['phone']!.length < 10 || data['phone']!.length > 13) return false;

  return true;
}

Map<String, String> _getInitialFormValues(Map<String, String> guardian) {
  return {
    'name': guardian['name'] ?? '',
    'address': guardian['address'] ?? '',
    'phone': guardian['phone'] ?? '',
  };
}

String _formatEditSuccessMessage() {
  return 'Data wali berhasil diperbarui';
}

String _formatEditError(String errorMessage) {
  return 'Gagal memperbarui data wali: $errorMessage';
}

bool _hasChanges(Map<String, String> original, Map<String, String> updated) {
  return original['name'] != updated['name'] ||
      original['address'] != updated['address'] ||
      original['phone'] != updated['phone'];
}

bool _isValidPhoneForEdit(String phone) {
  if (phone.length < 10 || phone.length > 13) return false;
  return RegExp(r'^\d+$').hasMatch(phone);
}

bool _isValidNameForEdit(String name) {
  return name.trim().isNotEmpty && name.trim().length >= 3;
}

// Mock guardian for testing
Map<String, String> _createMockGuardian() {
  return {
    'name': 'Original Name',
    'address': 'Original Address',
    'phone': '08123456789',
  };
}
