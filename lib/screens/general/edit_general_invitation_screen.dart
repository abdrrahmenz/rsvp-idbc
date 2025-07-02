import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../../providers/invitation_provider.dart';
import '../../models/general_invitation_model.dart';

class EditGeneralInvitationScreen extends StatefulWidget {
  final GeneralInvitation invitation;

  const EditGeneralInvitationScreen({
    Key? key,
    required this.invitation,
  }) : super(key: key);

  @override
  State<EditGeneralInvitationScreen> createState() =>
      _EditGeneralInvitationScreenState();
}

class _EditGeneralInvitationScreenState
    extends State<EditGeneralInvitationScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Undangan Umum'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invitation Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: Text(
                        widget.invitation.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Undangan:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            widget.invitation.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Undangan Umum',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
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
                'name': widget.invitation.name,
                'address': widget.invitation.address,
                'phone': widget.invitation.phone,
              },
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

                  // Current QR Code Info
                  if (widget.invitation.barcode != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.qr_code,
                              color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'QR Code yang ada akan tetap dapat digunakan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Kode: ${widget.invitation.barcode}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
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
                      label: Text(
                          _isLoading ? 'Menyimpan...' : 'Simpan Perubahan'),
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
      print('Form value keys: ${values.keys.toList()}');
      print('Name value: ${values['name']}');
      print('Address value: ${values['address']}');
      print('Phone value: ${values['phone']}');

      // Prepare and validate data with null safety
      final invitationData = <String, String>{
        'name': (values['name']?.toString() ?? '').trim(),
        'address': (values['address']?.toString() ?? '').trim(),
        'phone': (values['phone']?.toString() ?? '').trim(),
      };

      print('Prepared invitation data: $invitationData');

      // Additional validation
      if (invitationData['name']!.isEmpty) {
        throw Exception('Nama tidak boleh kosong');
      }
      if (invitationData['address']!.isEmpty) {
        throw Exception('Alamat tidak boleh kosong');
      }
      if (invitationData['phone']!.isEmpty) {
        throw Exception('No. HP tidak boleh kosong');
      }

      print('Updating invitation with ID: ${widget.invitation.id}');
      print('Submitting invitation data: $invitationData');

      await context.read<InvitationProvider>().updateGeneralInvitation(
            widget.invitation.id,
            invitationData,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Undangan berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back with success result
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      print('Error updating invitation: $e');
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
