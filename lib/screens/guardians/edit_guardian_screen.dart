import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../models/guardian_model.dart';

class EditGuardianScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final Guardian guardian;

  const EditGuardianScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.guardian,
  }) : super(key: key);

  @override
  State<EditGuardianScreen> createState() => _EditGuardianScreenState();
}

class _EditGuardianScreenState extends State<EditGuardianScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Wali/Orangtua'),
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
              initialValue: {
                'name': widget.guardian.name,
                'address': widget.guardian.address,
                'phone': widget.guardian.phone,
                'person_count': widget.guardian.personCount.toString(),
              },
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
                  ),
                  const SizedBox(height: 32),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Anda sedang mengedit data wali ${widget.guardian.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
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
                      label:
                          Text(_isLoading ? 'Menyimpan...' : 'Perbarui Data'),
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

      // Prepare and validate data with null safety
      final guardianData = <String, dynamic>{
        'name': (values['name']?.toString() ?? '').trim(),
        'address': (values['address']?.toString() ?? '').trim(),
        'phone': (values['phone']?.toString() ?? '').trim(),
        'person_count':
            int.tryParse(values['person_count']?.toString() ?? '1') ?? 1,
      };

      print('Updating guardian data: $guardianData');

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

      await context.read<StudentProvider>().updateGuardian(
            widget.guardian.id,
            widget.studentId,
            guardianData,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data wali berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      print('Error updating guardian: $e');
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
