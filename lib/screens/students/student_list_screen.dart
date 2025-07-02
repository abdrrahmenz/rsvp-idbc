import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'dart:io';
import 'dart:html' as html if (dart.library.html) 'dart:html';
import '../../providers/student_provider.dart';
import '../../widgets/qr_code_widget.dart';
import 'add_student_screen.dart';
import 'edit_student_screen.dart';
import 'bulk_import_screen.dart';
import '../guardians/guardian_list_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({Key? key}) : super(key: key);

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSelectionMode = false;
  Set<String> _selectedStudentIds = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<StudentProvider>().loadStudents();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSelectionMode
              ? Text('${_selectedStudentIds.length} dipilih')
              : const Text('Daftar Mahasiswa'),
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                )
              : null,
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: _selectAllStudents,
                    tooltip: 'Pilih semua',
                  ),
                  if (_selectedStudentIds.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _deleteSelectedStudents,
                      tooltip: 'Hapus yang dipilih',
                    ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.checklist),
                    onPressed: _enterSelectionMode,
                    tooltip: 'Pilih untuk hapus',
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.add),
                    onSelected: (value) {
                      if (value == 'single') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddStudentScreen()),
                        ).then((_) {
                          context.read<StudentProvider>().loadStudents();
                        });
                      } else if (value == 'bulk') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BulkImportScreen()),
                        ).then((_) {
                          context.read<StudentProvider>().loadStudents();
                        });
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'single',
                        child: Row(
                          children: [
                            Icon(Icons.person_add),
                            SizedBox(width: 8),
                            Text('Tambah Mahasiswa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'bulk',
                        child: Row(
                          children: [
                            Icon(Icons.upload_file),
                            SizedBox(width: 8),
                            Text('Import dari Excel'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
        ),
        body: Column(
          children: [
            // Selection Mode Info Banner
            if (_isSelectionMode)
              Container(
                width: double.infinity,
                color: Colors.blue[50],
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mode pilih aktif. Ketuk mahasiswa untuk memilih/membatalkan pilihan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _exitSelectionMode,
                      child:
                          const Text('Keluar', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari mahasiswa...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.toLowerCase());
                },
              ),
            ),

            // Student List
            Expanded(
              child: Consumer<StudentProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final students = provider.students.where((student) {
                    return student.name.toLowerCase().contains(_searchQuery) ||
                        student.phone.contains(_searchQuery);
                  }).toList();

                  if (students.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Belum ada mahasiswa'
                                : 'Mahasiswa tidak ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadStudents(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: _isSelectionMode
                                ? () => _toggleStudentSelection(student.id)
                                : () => _showStudentDetail(student),
                            onLongPress: _isSelectionMode
                                ? null
                                : () => _enterSelectionMode(student.id),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: _isSelectionMode &&
                                      _selectedStudentIds.contains(student.id)
                                  ? BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue[700]!,
                                        width: 2,
                                      ),
                                      color: Colors.blue[50],
                                    )
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Selection Checkbox or Avatar
                                    _isSelectionMode
                                        ? Checkbox(
                                            value: _selectedStudentIds
                                                .contains(student.id),
                                            onChanged: (_) =>
                                                _toggleStudentSelection(
                                                    student.id),
                                            activeColor: Colors.blue[700],
                                          )
                                        : CircleAvatar(
                                            radius: 30,
                                            backgroundColor: Colors.blue[100],
                                            child: Text(
                                              student.name[0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[700],
                                              ),
                                            ),
                                          ),
                                    const SizedBox(width: 16),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            student.phone,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                student.isCheckedIn ?? false
                                                    ? Icons.check_circle
                                                    : Icons.circle_outlined,
                                                size: 16,
                                                color:
                                                    student.isCheckedIn ?? false
                                                        ? Colors.green
                                                        : Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                student.isCheckedIn ?? false
                                                    ? 'Sudah Check-in'
                                                    : 'Belum Check-in',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: student.isCheckedIn ??
                                                          false
                                                      ? Colors.green
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Actions (hide in selection mode)
                                    if (!_isSelectionMode)
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.qr_code),
                                            onPressed: () =>
                                                _showQRCode(student),
                                            tooltip: 'Lihat QR Code',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.family_restroom),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      GuardianListScreen(
                                                    studentId: student.id,
                                                    studentName: student.name,
                                                  ),
                                                ),
                                              );
                                            },
                                            tooltip: 'Lihat Wali',
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                _editStudent(student);
                                              } else if (value == 'delete') {
                                                _deleteStudent(student);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit,
                                                        color: Colors.orange),
                                                    SizedBox(width: 8),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete,
                                                        color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Hapus'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            child: const Icon(Icons.more_vert),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetail(student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    student.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                student.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Details
              _buildDetailItem(Icons.phone, 'No. HP', student.phone),
              _buildDetailItem(Icons.home, 'Alamat', student.address),
              _buildDetailItem(
                Icons.calendar_today,
                'Terdaftar',
                _formatDate(student.createdAt),
              ),
              _buildDetailItem(
                Icons.qr_code,
                'Kode',
                student.barcode ?? '-',
              ),
              const SizedBox(height: 32),

              // Actions
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editStudent(student);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Data'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showQRCode(student);
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text('QR Code'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GuardianListScreen(
                                  studentId: student.id,
                                  studentName: student.name,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.family_restroom),
                          label: const Text('Wali'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQRCode(student) {
    if (student.barcode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR Code tidak tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: const Text('Mahasiswa'),
                        backgroundColor: Colors.blue[100],
                        labelStyle: TextStyle(color: Colors.blue[700]),
                      ),
                      const SizedBox(height: 16),
                      QrCodeWidget(
                        data: student.barcode!,
                        size: 200,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        student.barcode!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _shareQRCode(student.name),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Bagikan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareQRCode(String studentName) async {
    try {
      // Capture screenshot
      final image = await _screenshotController.capture();
      if (image == null) {
        throw Exception('Gagal mengambil screenshot');
      }

      if (kIsWeb) {
        // Web platform - download the image
        await _downloadImageWeb(image, studentName);
      } else {
        // Mobile platform - use share functionality
        await _shareImageMobile(image, studentName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan QR Code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareImageMobile(Uint8List image, String studentName) async {
    // Get temporary directory
    final directory = await getTemporaryDirectory();
    final imagePath =
        '${directory.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png';

    // Save image to file
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(image);

    // Share the image
    await Share.shareXFiles(
      [XFile(imagePath)],
      text: 'QR Code untuk $studentName',
      subject: 'QR Code Undangan Wisuda',
    );

    // Clean up the temporary file after a delay
    Future.delayed(const Duration(seconds: 30), () {
      if (imageFile.existsSync()) {
        imageFile.deleteSync();
      }
    });
  }

  Future<void> _downloadImageWeb(Uint8List image, String studentName) async {
    // Create blob and download link for web
    final blob = html.Blob([image], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download =
          'qr_code_${studentName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR Code untuk $studentName berhasil diunduh'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _enterSelectionMode([String? studentId]) {
    setState(() {
      _isSelectionMode = true;
      _selectedStudentIds.clear();
      if (studentId != null) {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedStudentIds.clear();
    });
  }

  void _toggleStudentSelection(String studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  void _selectAllStudents() {
    final provider = context.read<StudentProvider>();
    final students = provider.students.where((student) {
      return student.name.toLowerCase().contains(_searchQuery) ||
          student.phone.contains(_searchQuery);
    }).toList();

    setState(() {
      _selectedStudentIds = students.map((s) => s.id).toSet();
    });
  }

  Future<void> _deleteSelectedStudents() async {
    if (_selectedStudentIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${_selectedStudentIds.length} mahasiswa yang dipilih?\n\n'
          'Tindakan ini tidak dapat dibatalkan dan akan menghapus semua data terkait termasuk wali dan undangan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await context
          .read<StudentProvider>()
          .deleteStudents(_selectedStudentIds.toList());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Berhasil menghapus ${_selectedStudentIds.length} mahasiswa'),
            backgroundColor: Colors.green,
          ),
        );
        _exitSelectionMode();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editStudent(student) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStudentScreen(student: student),
      ),
    );

    // Refresh the student list if edit was successful
    if (result == true) {
      context.read<StudentProvider>().loadStudents();
    }
  }

  Future<void> _deleteStudent(student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menghapus mahasiswa berikut?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.phone,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Data yang telah dihapus tidak dapat dikembalikan. Semua data terkait termasuk wali dan undangan akan ikut terhapus.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<StudentProvider>().deleteStudent(student.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mahasiswa ${student.name} berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus mahasiswa: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
