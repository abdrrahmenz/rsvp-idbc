import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';

class AddGuardianScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const AddGuardianScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<AddGuardianScreen> createState() => _AddGuardianScreenState();
}

class _AddGuardianScreenState extends State<AddGuardianScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Wali/Orangtua'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        widget.studentName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mahasiswa:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            widget.studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Form
            FormBuilder(
              key: _formKey,
              child: Column(
                children: [
                  FormBuilderTextField(
                    name: 'name',
                    decoration: const InputDecoration(
                      labelText: 'Nama Wali/Orangtua',
                      hintText: 'Masukkan nama lengkap',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Nama wajib diisi'),
                      FormBuilderValidators.minLength(3,
                          errorText: 'Minimal 3 karakter'),
                    ]),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'address',
                    decoration: const InputDecoration(
                      labelText: 'Alamat',
                      hintText: 'Masukkan alamat lengkap',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Alamat wajib diisi',
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'phone',
                    decoration: const InputDecoration(
                      labelText: 'No. HP',
                      hintText: 'Contoh: 081234567890',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'No. HP wajib diisi'),
                      FormBuilderValidators.numeric(
                          errorText: 'Harus berupa angka'),
                      FormBuilderValidators.minLength(10,
                          errorText: 'Minimal 10 digit'),
                      FormBuilderValidators.maxLength(13,
                          errorText: 'Maksimal 13 digit'),
                    ]),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  FormBuilderTextField(
                    name: 'person_count',
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Orang yang Ikut',
                      hintText: 'Contoh: 2 (termasuk wali ini)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people),
                      helperText:
                          'Termasuk wali ini dan pendamping (saudara, anak, nenek, sepupu, dll)',
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                          errorText: 'Jumlah orang wajib diisi'),
                      FormBuilderValidators.numeric(
                          errorText: 'Harus berupa angka'),
                      FormBuilderValidators.min(1,
                          errorText: 'Minimal 1 orang'),
                      FormBuilderValidators.max(10,
                          errorText: 'Maksimal 10 orang'),
                    ]),
                    keyboardType: TextInputType.number,
                    initialValue: '1',
                  ),
                  const SizedBox(height: 32),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Setiap mahasiswa dapat mendaftarkan maksimal 3 wali/orangtua',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleSubmit,
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
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Menyimpan...' : 'Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Save and validate form first
    if (!_formKey.currentState!.saveAndValidate()) return;

    setState(() => _isLoading = true);

    try {
      final values = _formKey.currentState!.value;
      print('Form values: $values');
      print('Form value keys: ${values.keys.toList()}');
      print('Name value: ${values['name']}');
      print('Address value: ${values['address']}');
      print('Phone value: ${values['phone']}');

      // Prepare and validate data with null safety
      final guardianData = <String, dynamic>{
        'name': (values['name']?.toString() ?? '').trim(),
        'address': (values['address']?.toString() ?? '').trim(),
        'phone': (values['phone']?.toString() ?? '').trim(),
        'person_count':
            int.tryParse(values['person_count']?.toString() ?? '1') ?? 1,
        'student_id': widget.studentId,
      };

      print('Prepared guardian data: $guardianData');

      // Additional validation
      if (guardianData['name']!.isEmpty) {
        throw Exception('Nama tidak boleh kosong');
      }
      if (guardianData['address']!.isEmpty) {
        throw Exception('Alamat tidak boleh kosong');
      }
      if (guardianData['phone']!.isEmpty) {
        throw Exception('No. HP tidak boleh kosong');
      }

      print('Submitting guardian data: $guardianData');

      await context.read<StudentProvider>().addGuardian(guardianData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wali berhasil ditambahkan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear form and navigate back
      _formKey.currentState!.reset();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      print('Error submitting guardian: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
