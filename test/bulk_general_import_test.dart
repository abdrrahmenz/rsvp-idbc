import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Bulk General Invitation Import Tests', () {
    test('Should validate general invitation data correctly', () {
      final validData = {
        'name': 'Dr. Ahmad Fadli',
        'address': 'Jl. Veteran No. 123, Jakarta',
        'phone': '081234567890',
      };
      expect(_isValidGeneralInvitationData(validData), isTrue);

      final invalidDataEmptyName = {
        'name': '',
        'address': 'Jl. Veteran No. 123, Jakarta',
        'phone': '081234567890',
      };
      expect(_isValidGeneralInvitationData(invalidDataEmptyName), isFalse);

      final invalidDataEmptyAddress = {
        'name': 'Dr. Ahmad Fadli',
        'address': '',
        'phone': '081234567890',
      };
      expect(_isValidGeneralInvitationData(invalidDataEmptyAddress), isFalse);

      final invalidDataBadPhone = {
        'name': 'Dr. Ahmad Fadli',
        'address': 'Jl. Veteran No. 123, Jakarta',
        'phone': '123',
      };
      expect(_isValidGeneralInvitationData(invalidDataBadPhone), isFalse);
    });

    test('Should validate phone numbers for general invitations', () {
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

    test('Should validate required fields for general invitations', () {
      expect(_isValidName('Dr. Ahmad Fadli'), isTrue);
      expect(_isValidName('Prof. Siti Nurhaliza'), isTrue);
      expect(_isValidName(''), isFalse);
      expect(_isValidName('   '), isFalse);

      expect(_isValidAddress('Jl. Veteran No. 123, Jakarta'), isTrue);
      expect(_isValidAddress('Jl. Sudirman No. 456, Bandung'), isTrue);
      expect(_isValidAddress(''), isFalse);
      expect(_isValidAddress('   '), isFalse);
    });

    test('Should clean phone number correctly', () {
      expect(_cleanPhone('081-234-567-890'), equals('081234567890'));
      expect(_cleanPhone('081 234 567 890'), equals('081234567890'));
      expect(_cleanPhone('(081) 234-567-890'), equals('081234567890'));
      expect(_cleanPhone('+62 81 234 567 890'), equals('6281234567890'));
      expect(_cleanPhone('081234567890'), equals('081234567890'));
    });

    test('Should validate common general invitation names', () {
      final validNames = [
        'Dr. Ahmad Fadli',
        'Prof. Siti Nurhaliza',
        'H. Budi Santoso',
        'Dra. Maya Sari',
        'Ir. John Doe',
        'S.Pd. Jane Smith',
      ];

      for (final name in validNames) {
        expect(_isValidName(name), isTrue,
            reason: 'Name "$name" should be valid');
      }
    });

    test('Should handle various address formats', () {
      final validAddresses = [
        'Jl. Veteran No. 123, Jakarta',
        'Jl. Sudirman No. 456, Bandung, Jawa Barat',
        'Jl. Thamrin No. 789, RT 01/RW 02, Surabaya',
        'Kompleks Permata Indah Blok A No. 12, Medan',
      ];

      for (final address in validAddresses) {
        expect(_isValidAddress(address), isTrue,
            reason: 'Address "$address" should be valid');
      }
    });

    test('Should validate data structure for bulk import', () {
      final bulkData = [
        {
          'name': 'Dr. Ahmad Fadli',
          'address': 'Jl. Veteran No. 123, Jakarta',
          'phone': '081234567890',
        },
        {
          'name': 'Prof. Siti Nurhaliza',
          'address': 'Jl. Sudirman No. 456, Bandung',
          'phone': '087654321098',
        },
      ];

      expect(_validateBulkData(bulkData).isEmpty, isTrue);

      final invalidBulkData = [
        {
          'name': '',
          'address': 'Jl. Veteran No. 123, Jakarta',
          'phone': '081234567890',
        },
        {
          'name': 'Prof. Siti Nurhaliza',
          'address': '',
          'phone': '087654321098',
        },
      ];

      final errors = _validateBulkData(invalidBulkData);
      expect(errors.length, equals(2));
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

bool _isValidGeneralInvitationData(Map<String, String> data) {
  return _isValidName(data['name'] ?? '') &&
      _isValidAddress(data['address'] ?? '') &&
      _isValidPhone(data['phone'] ?? '');
}

List<String> _validateBulkData(List<Map<String, String>> bulkData) {
  List<String> errors = [];

  for (int i = 0; i < bulkData.length; i++) {
    final data = bulkData[i];

    if (!_isValidName(data['name'] ?? '')) {
      errors.add('Baris ${i + 1}: Nama tidak boleh kosong');
    }
    if (!_isValidAddress(data['address'] ?? '')) {
      errors.add('Baris ${i + 1}: Alamat tidak boleh kosong');
    }
    if (!_isValidPhone(data['phone'] ?? '')) {
      errors.add('Baris ${i + 1}: No. HP tidak valid');
    }
  }

  return errors;
}
