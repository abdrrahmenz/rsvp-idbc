import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({Key? key}) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Mahasiswa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            children: [
              FormBuilderTextField(
                name: 'name',
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(errorText: 'Nama wajib diisi'),
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
              const SizedBox(height: 32),
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
      final studentData = <String, String>{
        'name': (values['name']?.toString() ?? '').trim(),
        'address': (values['address']?.toString() ?? '').trim(),
        'phone': (values['phone']?.toString() ?? '').trim(),
      };

      print('Prepared student data: $studentData');

      // Additional validation
      if (studentData['name']!.isEmpty) {
        throw Exception('Nama tidak boleh kosong');
      }
      if (studentData['address']!.isEmpty) {
        throw Exception('Alamat tidak boleh kosong');
      }
      if (studentData['phone']!.isEmpty) {
        throw Exception('No. HP tidak boleh kosong');
      }

      print('Submitting student data: $studentData');

      await context.read<StudentProvider>().addStudent(studentData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mahasiswa berhasil ditambahkan'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear form and navigate back
      _formKey.currentState!.reset();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      print('Error submitting student: $e');
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
