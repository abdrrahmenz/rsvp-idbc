import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:provider/provider.dart';
import '../../providers/invitation_provider.dart';

class BulkGeneralInvitationScreen extends StatefulWidget {
  const BulkGeneralInvitationScreen({Key? key}) : super(key: key);

  @override
  State<BulkGeneralInvitationScreen> createState() =>
      _BulkGeneralInvitationScreenState();
}

class _BulkGeneralInvitationScreenState
    extends State<BulkGeneralInvitationScreen> {
  bool _isLoading = false;
  List<Map<String, String>> _invitations = [];
  List<String> _errors = [];
  String? _fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Undangan Umum dari Excel'),
        actions: [
          if (_invitations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showTemplateInfo,
              tooltip: 'Info Template',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Format File Excel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'File Excel harus memiliki kolom dengan urutan:\n'
                      '1. Nama Lengkap (kolom A)\n'
                      '2. Alamat (kolom B)\n'
                      '3. No. HP (kolom C)\n\n'
                      'Baris pertama akan diabaikan (header).',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // File Picker Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih File Excel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickFile,
                        icon: const Icon(Icons.file_upload),
                        label: Text(_fileName ?? 'Pilih File (.xlsx, .xls)'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (_fileName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'File dipilih: $_fileName',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Errors Section
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Error dalam File',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...(_errors.take(10).map((error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $error',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ))),
                      if (_errors.length > 10)
                        Text(
                          'Dan ${_errors.length - 10} error lainnya...',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Preview Section
            if (_invitations.isNotEmpty) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Preview Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            label: Text('${_invitations.length} undangan'),
                            backgroundColor: Colors.orange[100],
                            labelStyle: TextStyle(color: Colors.orange[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Preview List
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount:
                              _invitations.length > 5 ? 5 : _invitations.length,
                          itemBuilder: (context, index) {
                            final invitation = _invitations[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange[100],
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(color: Colors.orange[700]),
                                  ),
                                ),
                                title: Text(invitation['name'] ?? ''),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('HP: ${invitation['phone'] ?? ''}'),
                                    Text(
                                      'Alamat: ${invitation['address'] ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),

                      if (_invitations.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Menampilkan 5 dari ${_invitations.length} data...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // Import Button
            if (_invitations.isNotEmpty && _errors.isEmpty) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _importInvitations,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.upload),
                  label: Text(_isLoading
                      ? 'Mengimpor...'
                      : 'Import ${_invitations.length} Undangan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],

            // Download Template Button
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download),
                label: const Text('Download Template Excel'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _isLoading = true;
          _invitations.clear();
          _errors.clear();
          _fileName = result.files.single.name;
        });

        await _parseExcelFile(result.files.single.bytes!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _parseExcelFile(List<int> bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;

      List<Map<String, String>> invitations = [];
      List<String> errors = [];

      // Skip header row (start from row 1)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.rows[rowIndex];

        // Skip empty rows
        if (row.isEmpty || (row[0]?.value?.toString().trim().isEmpty ?? true)) {
          continue;
        }

        try {
          final name =
              row.length > 0 ? (row[0]?.value?.toString().trim() ?? '') : '';
          final address =
              row.length > 1 ? (row[1]?.value?.toString().trim() ?? '') : '';
          final phone =
              row.length > 2 ? (row[2]?.value?.toString().trim() ?? '') : '';

          // Validate required fields
          if (name.isEmpty) {
            errors.add('Baris ${rowIndex + 1}: Nama tidak boleh kosong');
            continue;
          }
          if (address.isEmpty) {
            errors.add('Baris ${rowIndex + 1}: Alamat tidak boleh kosong');
            continue;
          }
          if (phone.isEmpty) {
            errors.add('Baris ${rowIndex + 1}: No. HP tidak boleh kosong');
            continue;
          }

          // Validate phone number
          final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
          if (cleanPhone.length < 10 || cleanPhone.length > 13) {
            errors.add('Baris ${rowIndex + 1}: No. HP tidak valid (${phone})');
            continue;
          }

          invitations.add({
            'name': name,
            'address': address,
            'phone': cleanPhone,
          });
        } catch (e) {
          errors.add(
              'Baris ${rowIndex + 1}: Error parsing data - ${e.toString()}');
        }
      }

      setState(() {
        _invitations = invitations;
        _errors = errors;
      });

      if (mounted) {
        if (invitations.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Berhasil memuat ${invitations.length} data undangan'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (errors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File berisi ${errors.length} error'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada data valid ditemukan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errors = ['Error membaca file Excel: ${e.toString()}'];
      });
    }
  }

  Future<void> _importInvitations() async {
    if (_invitations.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final importErrors = await context
          .read<InvitationProvider>()
          .addGeneralInvitationsBulk(_invitations);

      final successCount = _invitations.length - importErrors.length;

      if (mounted) {
        if (successCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil mengimpor $successCount undangan'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        if (importErrors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${importErrors.length} data gagal diimpor'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Lihat',
                onPressed: () => _showImportErrors(importErrors),
              ),
            ),
          );
        }

        // Navigate back on success
        if (successCount > 0) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saat mengimpor: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImportErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Gagal Diimpor'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: errors.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• ${errors[index]}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showTemplateInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Format Template Excel'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Excel harus memiliki struktur sebagai berikut:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Kolom A: Nama Lengkap'),
            Text('Kolom B: Alamat'),
            Text('Kolom C: No. HP'),
            SizedBox(height: 16),
            Text(
              'Catatan:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('• Baris pertama akan diabaikan (header)'),
            Text('• No. HP harus 10-13 digit'),
            Text('• Semua kolom wajib diisi'),
            Text('• Undangan umum untuk tamu di luar mahasiswa/wali'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _downloadTemplate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Template Excel Format Undangan Umum:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Kolom A: Nama Lengkap'),
            Text('Kolom B: Alamat'),
            Text('Kolom C: No. HP'),
            SizedBox(height: 8),
            Text(
              'Contoh data:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Dr. Ahmad | Jl. Veteran No. 123, Jakarta | 081234567890'),
            Text('Siti Rahma | Jl. Merdeka No. 456, Bandung | 087654321098'),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
