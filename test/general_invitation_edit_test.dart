import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../lib/screens/general/edit_general_invitation_screen.dart';
import '../lib/providers/invitation_provider.dart';
import '../lib/models/general_invitation_model.dart';

class MockInvitationProvider extends InvitationProvider {
  bool updateCalled = false;
  Map<String, dynamic>? lastUpdateData;
  String? lastUpdateId;
  bool shouldThrowError = false;

  @override
  Future<void> updateGeneralInvitation(
      String id, Map<String, dynamic> data) async {
    updateCalled = true;
    lastUpdateId = id;
    lastUpdateData = data;

    if (shouldThrowError) {
      throw Exception('Test error');
    }

    await Future.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('EditGeneralInvitationScreen Tests', () {
    late MockInvitationProvider mockProvider;
    late GeneralInvitation testInvitation;

    setUp(() {
      mockProvider = MockInvitationProvider();
      testInvitation = GeneralInvitation(
        id: 'test-id-123',
        name: 'John Doe',
        address: 'Jl. Test No. 123',
        phone: '081234567890',
        createdAt: DateTime.now(),
        barcode: 'TEST-BARCODE-123',
        isCheckedIn: false,
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<InvitationProvider>.value(
          value: mockProvider,
          child: EditGeneralInvitationScreen(invitation: testInvitation),
        ),
      );
    }

    testWidgets('should display screen title correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Edit Undangan Umum'), findsOneWidget);
    });

    testWidgets('should display invitation name in header card',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('John Doe'), findsAtLeastNWidgets(1));
      expect(find.text('Edit Undangan:'), findsOneWidget);
    });

    testWidgets('should display QR code preservation info when barcode exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('QR Code yang ada akan tetap dapat digunakan'),
          findsOneWidget);
      expect(find.text('Kode: TEST-BARCODE-123'), findsOneWidget);
    });

    testWidgets('should not display QR code info when barcode is null',
        (WidgetTester tester) async {
      final invitationWithoutBarcode = GeneralInvitation(
        id: 'test-id-456',
        name: 'Jane Doe',
        address: 'Jl. Test No. 456',
        phone: '081234567891',
        createdAt: DateTime.now(),
        barcode: null,
        isCheckedIn: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<InvitationProvider>.value(
            value: mockProvider,
            child: EditGeneralInvitationScreen(
                invitation: invitationWithoutBarcode),
          ),
        ),
      );

      expect(find.text('QR Code yang ada akan tetap dapat digunakan'),
          findsNothing);
    });

    testWidgets('should display proper form field labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Alamat'), findsOneWidget);
      expect(find.text('No. HP'), findsOneWidget);
    });

    testWidgets('should have submit button with correct text',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });

    testWidgets('should call updateGeneralInvitation with correct data',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find form fields and enter new data
      final nameField = find
          .ancestor(
            of: find.text('Nama Lengkap'),
            matching: find.byType(TextFormField),
          )
          .first;
      await tester.enterText(nameField, 'John Smith');

      final addressField = find
          .ancestor(
            of: find.text('Alamat'),
            matching: find.byType(TextFormField),
          )
          .first;
      await tester.enterText(addressField, 'Jl. New Address');

      final phoneField = find
          .ancestor(
            of: find.text('No. HP'),
            matching: find.byType(TextFormField),
          )
          .first;
      await tester.enterText(phoneField, '081987654321');

      // Submit form
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Verify the method was called
      expect(mockProvider.updateCalled, isTrue);
      expect(mockProvider.lastUpdateId, equals('test-id-123'));
      expect(mockProvider.lastUpdateData?['name'], equals('John Smith'));
      expect(
          mockProvider.lastUpdateData?['address'], equals('Jl. New Address'));
      expect(mockProvider.lastUpdateData?['phone'], equals('081987654321'));
    });

    testWidgets('should show loading state during update',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Submit form
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pump();

      // Check loading state
      expect(find.text('Menyimpan...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should handle errors gracefully', (WidgetTester tester) async {
      mockProvider.shouldThrowError = true;
      await tester.pumpWidget(createTestWidget());

      // Submit form
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Check that error message is shown (SnackBar)
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should display form field icons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(
          find.byIcon(Icons.qr_code), findsOneWidget); // QR preservation info
      expect(find.byIcon(Icons.edit), findsOneWidget); // Header icon
    });
  });
}
