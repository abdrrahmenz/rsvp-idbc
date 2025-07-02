import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../providers/invitation_provider.dart';

class AddGeneralInvitationScreen extends StatefulWidget {
  const AddGeneralInvitationScreen({Key? key}) : super(key: key);

  @override
  State<AddGeneralInvitationScreen> createState() =>
      _AddGeneralInvitationScreenState();
}

class _AddGeneralInvitationScreenState
    extends State<AddGeneralInvitationScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Undangan Umum'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              elevation: 2,
              color: Colors.orange[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.orange[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Undangan umum adalah undangan untuk tamu di luar mahasiswa dan wali',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[900],
                        ),
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
                      labelText: 'Nama Lengkap',
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
                  const SizedBox(height: 32),

                  // Additional Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Tambahan:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.qr_code, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'QR Code akan dibuat otomatis setelah menyimpan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.mail_outline, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Undangan dapat dikirim melalui WhatsApp atau email',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
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
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    // Save form to get values
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final values = _formKey.currentState!.value;
      
      // Debug print
      print('Form values: $values');
      print('Name: ${values['name']}');
      print('Address: ${values['address']}');
      print('Phone: ${values['phone']}');
      
      // Ensure values are not null and trim whitespace
      final data = {
        'name': values['name']?.toString().trim() ?? '',
        'address': values['address']?.toString().trim() ?? '',
        'phone': values['phone']?.toString().trim() ?? '',
      };
      
      // Validate again
      if (data['name']!.isEmpty) {
        throw Exception('Nama tidak boleh kosong');
      }
      if (data['address']!.isEmpty) {
        throw Exception('Alamat tidak boleh kosong');
      }
      if (data['phone']!.isEmpty) {
        throw Exception('No. HP tidak boleh kosong');
      }
      
      await context.read<InvitationProvider>().addGeneralInvitation(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Undangan umum berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error submitting form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}