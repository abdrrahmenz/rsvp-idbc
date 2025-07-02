import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/invitation_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) async {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue == null) continue;

      setState(() => isScanning = false);

      try {
        final result = await context
            .read<InvitationProvider>()
            .checkInByBarcode(barcode.rawValue!);

        if (!mounted) return;

        if (result['success']) {
          _showSuccessDialog(result['data']);
        } else {
          _showErrorDialog(result['message']);
        }
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Check-in Berhasil!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama: ${data['name']}'),
            Text('Tipe: ${data['type']}'),
            Text('No. HP: ${data['phone']}'),
            if (data['student_name'] != null)
              Text('Mahasiswa: ${data['student_name']}'),
            if (data['type'] == 'Wali/Orangtua')
              Text('Jumlah Orang: ${data['person_count']}'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanning = true);
            },
            child: const Text('Scan Lagi'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 64),
        title: const Text('Gagal!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanning = true);
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        List<Map<String, dynamic>> dialogSearchResults = [];
        bool dialogIsSearching = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> searchInDialog(String query) async {
              if (query.trim().isEmpty) {
                setDialogState(() {
                  dialogSearchResults = [];
                  dialogIsSearching = false;
                });
                return;
              }

              setDialogState(() {
                dialogIsSearching = true;
              });

              try {
                final provider = context.read<InvitationProvider>();

                // Load all invitations if not loaded yet
                await provider.loadInvitations();
                await provider.loadGeneralInvitations();

                final filteredResults = <Map<String, dynamic>>[];
                final searchTerm = query.toLowerCase();

                // Deduplication strategy: Use multiple layers to prevent any duplicates
                // 1. Unique keys (type_id) - prevents exact same record
                // 2. Name+phone combinations - prevents same person with different types
                // 3. Barcodes - prevents same barcode appearing multiple times
                final addedKeys =
                    <String>{}; // Track unique keys to prevent ALL duplicates
                final namePhoneCombos =
                    <String>{}; // Track name+phone combinations
                final barcodes =
                    <String>{}; // Track barcodes to prevent duplicates

                // Search through regular invitations (students and guardians only)
                // Skip general invitations here to avoid duplicates with generalInvitations list
                for (final invitation in provider.invitations) {
                  // Skip general invitations here to avoid duplicates
                  if (invitation.invitationType == 'general') continue;

                  final name = (invitation.name ?? '').toLowerCase();
                  final address = (invitation.address ?? '').toLowerCase();
                  final phone = (invitation.phone ?? '').toLowerCase();

                  if (name.contains(searchTerm) ||
                      address.contains(searchTerm) ||
                      phone.contains(searchTerm)) {
                    String type = 'Umum';
                    if (invitation.invitationType == 'student') {
                      type = 'Mahasiswa';
                    } else if (invitation.invitationType == 'guardian') {
                      type = 'Wali';
                    }

                    // Create unique key based on type and reference
                    final uniqueKey =
                        '${invitation.invitationType}_${invitation.id}';
                    final namePhoneCombo =
                        '${invitation.name ?? ''}_${invitation.phone ?? ''}'
                            .toLowerCase();
                    final barcode = invitation.barcode;

                    if (!addedKeys.contains(uniqueKey) &&
                        !namePhoneCombos.contains(namePhoneCombo) &&
                        (barcode.isEmpty || !barcodes.contains(barcode))) {
                      addedKeys.add(uniqueKey);
                      namePhoneCombos.add(namePhoneCombo);
                      if (barcode.isNotEmpty) barcodes.add(barcode);

                      filteredResults.add({
                        'id': invitation.id,
                        'name': invitation.name ?? '',
                        'address': invitation.address ?? '',
                        'phone': invitation.phone ?? '',
                        'barcode': barcode,
                        'is_checked_in': invitation.isCheckedIn,
                        'type': type,
                        'student_name': invitation.studentName,
                        'person_count': invitation.personCount,
                        'unique_key': uniqueKey, // For debugging
                      });
                    }
                  }
                }

                // Search through general invitations (only from generalInvitations list)
                for (final generalInvitation in provider.generalInvitations) {
                  final name = generalInvitation.name.toLowerCase();
                  final address = generalInvitation.address.toLowerCase();
                  final phone = generalInvitation.phone.toLowerCase();

                  if (name.contains(searchTerm) ||
                      address.contains(searchTerm) ||
                      phone.contains(searchTerm)) {
                    // Create unique key for general invitation
                    final uniqueKey = 'general_${generalInvitation.id}';
                    final namePhoneCombo =
                        '${generalInvitation.name}_${generalInvitation.phone}'
                            .toLowerCase();
                    final barcode = generalInvitation.barcode ?? '';

                    // Check for all forms of duplicates: unique key, name+phone combo, and barcode
                    if (!addedKeys.contains(uniqueKey) &&
                        !namePhoneCombos.contains(namePhoneCombo) &&
                        (barcode.isEmpty || !barcodes.contains(barcode))) {
                      addedKeys.add(uniqueKey);
                      namePhoneCombos.add(namePhoneCombo);
                      if (barcode.isNotEmpty) barcodes.add(barcode);

                      filteredResults.add({
                        'id': generalInvitation.id,
                        'name': generalInvitation.name,
                        'address': generalInvitation.address,
                        'phone': generalInvitation.phone,
                        'barcode': barcode,
                        'is_checked_in': generalInvitation.isCheckedIn ?? false,
                        'type': 'Umum',
                        'student_name': null,
                        'unique_key': uniqueKey, // For debugging
                      });
                    }
                  }
                }

                setDialogState(() {
                  dialogSearchResults = filteredResults;
                  dialogIsSearching = false;
                });

                // Debug logging
                print('=== SEARCH RESULTS DEBUG ===');
                print('Search term: "$searchTerm"');
                print('Total results found: ${filteredResults.length}');
                print('Unique keys tracked: ${addedKeys.length}');
                print('Name+phone combinations: ${namePhoneCombos.length}');
                print('Barcodes tracked: ${barcodes.length}');
                print('Results breakdown:');
                for (int i = 0; i < filteredResults.length; i++) {
                  final result = filteredResults[i];
                  print(
                      '  ${i + 1}. ${result['name']} (${result['type']}) - Key: ${result['unique_key']} - Phone: ${result['phone']} - Barcode: ${result['barcode']}');
                }
                print('=============================');
              } catch (e) {
                setDialogState(() {
                  dialogIsSearching = false;
                  dialogSearchResults = [];
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error pencarian: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.search, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Cari Undangan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Search Field
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Cari berdasarkan nama, alamat, atau no HP',
                        hintText: 'Masukkan kata kunci pencarian',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setDialogState(() {});
                                  searchInDialog('');
                                },
                                icon: const Icon(Icons.clear),
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                        searchInDialog(value);
                      },
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),

                    // Search Results
                    Expanded(
                      child: dialogIsSearching
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : dialogSearchResults.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        searchController.text.isEmpty
                                            ? 'Mulai mengetik untuk mencari undangan'
                                            : 'Tidak ada undangan yang ditemukan',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: dialogSearchResults.length,
                                  itemBuilder: (context, index) {
                                    final invitation =
                                        dialogSearchResults[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              invitation['is_checked_in']
                                                  ? Colors.green
                                                  : Colors.blue,
                                          child: Icon(
                                            invitation['is_checked_in']
                                                ? Icons.check_circle
                                                : invitation['type'] ==
                                                        'Mahasiswa'
                                                    ? Icons.school
                                                    : invitation['type'] ==
                                                            'Wali'
                                                        ? Icons.family_restroom
                                                        : Icons.people,
                                            color: Colors.white,
                                          ),
                                        ),
                                        title: Text(
                                          invitation['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (invitation['student_name'] !=
                                                    null &&
                                                invitation['student_name']
                                                    .toString()
                                                    .isNotEmpty)
                                              Text(
                                                  'Mahasiswa: ${invitation['student_name']}'),
                                            Text(
                                                '${invitation['type']} • ${invitation['phone']}'),
                                            if (invitation['type'] == 'Wali' &&
                                                invitation['person_count'] !=
                                                    null)
                                              Text(
                                                '${invitation['person_count']} orang',
                                                style: TextStyle(
                                                  color: Colors.blue[600],
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            if (invitation['address']
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                invitation['address'],
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                        trailing: invitation['is_checked_in']
                                            ? const Chip(
                                                label: Text(
                                                  'Sudah Hadir',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                backgroundColor: Colors.green,
                                              )
                                            : FilledButton(
                                                onPressed: () async {
                                                  Navigator.pop(context);

                                                  // Perform check-in using barcode
                                                  if (invitation['barcode'] !=
                                                          null &&
                                                      invitation['barcode']
                                                          .toString()
                                                          .isNotEmpty) {
                                                    try {
                                                      setState(() =>
                                                          isScanning = false);

                                                      final result = await context
                                                          .read<
                                                              InvitationProvider>()
                                                          .checkInByBarcode(
                                                              invitation[
                                                                  'barcode']);

                                                      if (!mounted) return;

                                                      if (result['success']) {
                                                        _showSuccessDialog(
                                                            result['data']);
                                                      } else {
                                                        _showErrorDialog(
                                                            result['message']);
                                                      }
                                                    } catch (e) {
                                                      _showErrorDialog(
                                                          e.toString());
                                                    }
                                                  } else {
                                                    _showErrorDialog(
                                                        'QR Code tidak tersedia untuk undangan ini');
                                                  }
                                                },
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                ),
                                                child: const Text(
                                                  'Check-in',
                                                  style:
                                                      TextStyle(fontSize: 12),
                                                ),
                                              ),
                                        isThreeLine: true,
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManualInputDialog() {
    final barcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Input Manual Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan barcode secara manual:'),
            const SizedBox(height: 16),
            TextField(
              controller: barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode',
                hintText: 'Contoh: STD-1234567890-1234',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final barcode = barcodeController.text.trim();
              if (barcode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Barcode tidak boleh kosong'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                setState(() => isScanning = false);

                final result = await context
                    .read<InvitationProvider>()
                    .checkInByBarcode(barcode);

                if (!mounted) return;

                if (result['success']) {
                  _showSuccessDialog(result['data']);
                } else {
                  _showErrorDialog(result['message']);
                }
              } catch (e) {
                _showErrorDialog(e.toString());
              }
            },
            child: const Text('Check-in'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showSearchDialog,
            icon: const Icon(Icons.search),
            tooltip: 'Cari Undangan',
          ),
          IconButton(
            onPressed: _showManualInputDialog,
            icon: const Icon(Icons.keyboard),
            tooltip: 'Input Manual',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: cameraController,
            onDetect: _handleDetection,
          ),

          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Arahkan kamera ke QR Code undangan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Atau gunakan tombol pencarian untuk mencari undangan secara manual',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _showSearchDialog,
                        icon: const Icon(Icons.search, size: 18),
                        label: const Text('Cari'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showManualInputDialog,
                        icon: const Icon(Icons.keyboard, size: 18),
                        label: const Text('Manual'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showSearchDialog,
            backgroundColor: Colors.blue,
            heroTag: "search",
            child: const Icon(Icons.search, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showManualInputDialog,
            backgroundColor: Colors.green,
            heroTag: "manual",
            child: const Icon(Icons.keyboard, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
    double? cutOutWidth,
    double? cutOutHeight,
  })  : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
        cutOutHeight = cutOutHeight ?? cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(
            rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutWidth =
        this.cutOutWidth < width ? this.cutOutWidth : width - borderWidth;
    final cutOutHeight =
        this.cutOutHeight < height ? this.cutOutHeight : height - borderWidth;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2 + borderWidth,
      rect.top + (height - cutOutHeight) / 2 + borderWidth,
      cutOutWidth - borderWidth * 2,
      cutOutHeight - borderWidth * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndCorners(
          cutOutRect,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        Paint()..blendMode = BlendMode.clear,
      )
      ..restore();

    // Draw border
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        cutOutRect,
        topLeft: Radius.circular(borderRadius),
        topRight: Radius.circular(borderRadius),
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ),
      boxPaint,
    );

    // Draw corner lines
    final borderOffset = borderWidth / 2;
    final offset = borderOffset + borderRadius;
    final size = borderLength;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left - borderOffset, cutOutRect.top + offset + size)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.top + offset)
        ..quadraticBezierTo(
            cutOutRect.left - borderOffset,
            cutOutRect.top - borderOffset,
            cutOutRect.left + offset,
            cutOutRect.top - borderOffset)
        ..lineTo(
            cutOutRect.left + offset + size, cutOutRect.top - borderOffset),
      boxPaint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(
            cutOutRect.right - offset - size, cutOutRect.top - borderOffset)
        ..lineTo(cutOutRect.right - offset, cutOutRect.top - borderOffset)
        ..quadraticBezierTo(
            cutOutRect.right + borderOffset,
            cutOutRect.top - borderOffset,
            cutOutRect.right + borderOffset,
            cutOutRect.top + offset)
        ..lineTo(
            cutOutRect.right + borderOffset, cutOutRect.top + offset + size),
      boxPaint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(
            cutOutRect.left - borderOffset, cutOutRect.bottom - offset - size)
        ..lineTo(cutOutRect.left - borderOffset, cutOutRect.bottom - offset)
        ..quadraticBezierTo(
            cutOutRect.left - borderOffset,
            cutOutRect.bottom + borderOffset,
            cutOutRect.left + offset,
            cutOutRect.bottom + borderOffset)
        ..lineTo(
            cutOutRect.left + offset + size, cutOutRect.bottom + borderOffset),
      boxPaint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(
            cutOutRect.right - offset - size, cutOutRect.bottom + borderOffset)
        ..lineTo(cutOutRect.right - offset, cutOutRect.bottom + borderOffset)
        ..quadraticBezierTo(
            cutOutRect.right + borderOffset,
            cutOutRect.bottom + borderOffset,
            cutOutRect.right + borderOffset,
            cutOutRect.bottom - offset)
        ..lineTo(
            cutOutRect.right + borderOffset, cutOutRect.bottom - offset - size),
      boxPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
