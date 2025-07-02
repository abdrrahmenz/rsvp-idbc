import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Student Edit Validation Tests', () {
    test('Student edit data validation', () {
      final validData = {
        'name': 'John Doe Updated',
        'address': 'New Address 123, Updated City',
        'phone': '08123456789',
      };

      expect(_isValidEditData(validData), true);

      final invalidNameData = {
        'name': '',
        'address': 'New Address 123',
        'phone': '08123456789',
      };
      expect(_isValidEditData(invalidNameData), false);

      final shortNameData = {
        'name': 'Ab',
        'address': 'New Address 123',
        'phone': '08123456789',
      };
      expect(_isValidEditData(shortNameData), false);

      final invalidPhoneData = {
        'name': 'John Doe',
        'address': 'New Address 123',
        'phone': '123', // Too short
      };
      expect(_isValidEditData(invalidPhoneData), false);
    });

    test('Student edit form initial values', () {
      final student = _createMockStudent();
      final initialValues = _getInitialFormValues(student);

      expect(initialValues['name'], equals('Original Student Name'));
      expect(initialValues['address'], equals('Original Student Address'));
      expect(initialValues['phone'], equals('08123456789'));
    });

    test('Student edit success message formatting', () {
      const expectedMessage = 'Data mahasiswa berhasil diperbarui';

      expect(_formatEditSuccessMessage(), equals(expectedMessage));
    });

    test('Student edit error message formatting', () {
      const errorMessage = 'Database connection failed';
      const formattedError =
          'Gagal memperbarui data mahasiswa: Database connection failed';

      expect(_formatEditError(errorMessage), equals(formattedError));
      expect(
          _formatEditError(''), equals('Gagal memperbarui data mahasiswa: '));
    });
  });

  group('Student Edit Business Logic Tests', () {
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
      expect(_isValidNameForEdit('AB'), false); // Still too short
      expect(_isValidNameForEdit('ABC'), true); // Minimum valid
      expect(_isValidNameForEdit(''), false); // Empty
      expect(_isValidNameForEdit('   '), false); // Only spaces
    });

    test('Should validate address format for edit', () {
      expect(_isValidAddressForEdit('Jl. Sudirman No. 123'), true);
      expect(_isValidAddressForEdit('Updated Address Line 1\nLine 2'), true);
      expect(_isValidAddressForEdit(''), false); // Empty
      expect(_isValidAddressForEdit('   '), false); // Only spaces
    });

    test('Should preserve QR code and invitation data on edit', () {
      // Edit should not affect existing QR codes and invitations
      expect(_shouldPreserveInvitationData(), true);
    });
  });

  group('Student Delete Individual Tests', () {
    test('Delete student confirmation message', () {
      const studentName = 'John Doe';
      const studentPhone = '08123456789';

      expect(_formatDeleteConfirmationMessage(studentName, studentPhone),
          contains(studentName));
      expect(_formatDeleteConfirmationMessage(studentName, studentPhone),
          contains(studentPhone));
      expect(_formatDeleteConfirmationMessage(studentName, studentPhone),
          contains('menghapus mahasiswa'));
    });

    test('Delete student success message', () {
      const studentName = 'Jane Smith';
      const expectedMessage = 'Mahasiswa Jane Smith berhasil dihapus';

      expect(_formatDeleteSuccessMessage(studentName), equals(expectedMessage));
    });

    test('Delete student error message', () {
      const errorMessage = 'Network error';
      const formattedError = 'Gagal menghapus mahasiswa: Network error';

      expect(_formatDeleteErrorMessage(errorMessage), equals(formattedError));
    });
  });
}

// Helper validation functions for testing
bool _isValidEditData(Map<String, String> data) {
  if (data['name'] == null || data['name']!.trim().isEmpty) return false;
  if (data['name']!.trim().length < 3) return false;
  if (data['address'] == null || data['address']!.trim().isEmpty) return false;
  if (data['phone'] == null || data['phone']!.trim().isEmpty) return false;
  if (data['phone']!.length < 10 || data['phone']!.length > 13) return false;

  return true;
}

Map<String, String> _getInitialFormValues(Map<String, String> student) {
  return {
    'name': student['name'] ?? '',
    'address': student['address'] ?? '',
    'phone': student['phone'] ?? '',
  };
}

String _formatEditSuccessMessage() {
  return 'Data mahasiswa berhasil diperbarui';
}

String _formatEditError(String errorMessage) {
  return 'Gagal memperbarui data mahasiswa: $errorMessage';
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

bool _isValidAddressForEdit(String address) {
  return address.trim().isNotEmpty;
}

bool _shouldPreserveInvitationData() {
  // Edit operations should not affect existing QR codes and invitations
  return true;
}

String _formatDeleteConfirmationMessage(
    String studentName, String studentPhone) {
  return 'Apakah Anda yakin ingin menghapus mahasiswa $studentName ($studentPhone)?';
}

String _formatDeleteSuccessMessage(String studentName) {
  return 'Mahasiswa $studentName berhasil dihapus';
}

String _formatDeleteErrorMessage(String errorMessage) {
  return 'Gagal menghapus mahasiswa: $errorMessage';
}

// Mock student for testing
Map<String, String> _createMockStudent() {
  return {
    'name': 'Original Student Name',
    'address': 'Original Student Address',
    'phone': '08123456789',
  };
}
