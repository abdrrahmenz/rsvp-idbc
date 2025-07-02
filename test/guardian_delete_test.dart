import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Guardian Delete Validation Tests', () {
    test('Guardian ID validation', () {
      expect(_isValidGuardianId(''), false);
      expect(_isValidGuardianId('  '), false);
      expect(_isValidGuardianId('valid-uuid'), true);
      expect(_isValidGuardianId('123'), true);
      expect(_isValidGuardianId('guardian-123-abc'), true);
    });

    test('Student ID validation', () {
      expect(_isValidStudentId(''), false);
      expect(_isValidStudentId('  '), false);
      expect(_isValidStudentId('valid-uuid'), true);
      expect(_isValidStudentId('123'), true);
      expect(_isValidStudentId('student-123-abc'), true);
    });

    test('Guardian delete confirmation dialog text validation', () {
      const guardianName = 'John Doe';
      const guardianPhone = '08123456789';

      expect(_formatConfirmationMessage(guardianName, guardianPhone),
          contains(guardianName));
      expect(_formatConfirmationMessage(guardianName, guardianPhone),
          contains(guardianPhone));
      expect(_formatConfirmationMessage(guardianName, guardianPhone),
          contains('menghapus wali'));
    });

    test('Guardian delete error message formatting', () {
      const errorMessage = 'Database connection failed';
      const formattedError = 'Gagal menghapus wali: Database connection failed';

      expect(_formatDeleteError(errorMessage), equals(formattedError));
      expect(_formatDeleteError(''), equals('Gagal menghapus wali: '));
    });

    test('Guardian delete success message formatting', () {
      const guardianName = 'Jane Smith';
      const expectedMessage = 'Wali Jane Smith berhasil dihapus';

      expect(_formatSuccessMessage(guardianName), equals(expectedMessage));
      expect(_formatSuccessMessage(''), equals('Wali  berhasil dihapus'));
    });
  });

  group('Guardian Delete Business Logic Tests', () {
    test('Should allow delete when guardian exists', () {
      expect(_canDeleteGuardian(guardianExists: true), true);
    });

    test('Should not allow delete when guardian does not exist', () {
      expect(_canDeleteGuardian(guardianExists: false), false);
    });

    test('Should validate guardian belongs to student', () {
      expect(
          _isGuardianBelongsToStudent('guardian1', 'student1',
              {'guardian1': 'student1', 'guardian2': 'student2'}),
          true);

      expect(
          _isGuardianBelongsToStudent('guardian1', 'student2',
              {'guardian1': 'student1', 'guardian2': 'student2'}),
          false);
    });
  });
}

// Helper validation functions for testing
bool _isValidGuardianId(String guardianId) {
  return guardianId.isNotEmpty && guardianId.trim().isNotEmpty;
}

bool _isValidStudentId(String studentId) {
  return studentId.isNotEmpty && studentId.trim().isNotEmpty;
}

String _formatConfirmationMessage(String guardianName, String guardianPhone) {
  return 'Apakah Anda yakin ingin menghapus wali $guardianName ($guardianPhone)?';
}

String _formatDeleteError(String errorMessage) {
  return 'Gagal menghapus wali: $errorMessage';
}

String _formatSuccessMessage(String guardianName) {
  return 'Wali $guardianName berhasil dihapus';
}

bool _canDeleteGuardian({required bool guardianExists}) {
  return guardianExists;
}

bool _isGuardianBelongsToStudent(String guardianId, String studentId,
    Map<String, String> guardianStudentMap) {
  return guardianStudentMap[guardianId] == studentId;
}
