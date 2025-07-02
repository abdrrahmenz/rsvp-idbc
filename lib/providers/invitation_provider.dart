import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation_model.dart';
import '../models/general_invitation_model.dart';
import 'dashboard_provider.dart';

class InvitationProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Invitation> _invitations = [];
  List<GeneralInvitation> _generalInvitations = [];
  bool _isLoading = false;
  DashboardProvider? _dashboardProvider;

  List<Invitation> get invitations => _invitations;
  List<GeneralInvitation> get generalInvitations => _generalInvitations;
  bool get isLoading => _isLoading;

  // Set dashboard provider for automatic refresh
  void setDashboardProvider(DashboardProvider? dashboardProvider) {
    _dashboardProvider = dashboardProvider;
  }

  // Helper method to refresh dashboard statistics
  void _refreshDashboard() {
    _dashboardProvider?.refreshStatistics();
  }

  Future<void> loadInvitations() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Load invitations with manual joins
      final invitationsData = await _supabase
          .from('invitations')
          .select('*')
          .order('created_at', ascending: false);

      // Load related data based on invitation type
      List<Invitation> processedInvitations = [];

      for (var inv in invitationsData) {
        Map<String, dynamic> invitationData = Map.from(inv);

        // Get related data based on type
        switch (inv['invitation_type']) {
          case 'student':
            final studentData = await _supabase
                .from('students')
                .select('name, phone, address')
                .eq('id', inv['reference_id'])
                .maybeSingle();
            if (studentData != null) {
              invitationData.addAll({
                'name': studentData['name'],
                'phone': studentData['phone'],
                'address': studentData['address'],
              });
            }
            break;

          case 'guardian':
            final guardianData = await _supabase
                .from('guardians')
                .select('name, phone, address, student_id, person_count')
                .eq('id', inv['reference_id'])
                .maybeSingle();
            if (guardianData != null) {
              invitationData.addAll({
                'name': guardianData['name'],
                'phone': guardianData['phone'],
                'address': guardianData['address'],
                'person_count': guardianData['person_count'] ?? 1,
              });

              // Get student name
              final studentData = await _supabase
                  .from('students')
                  .select('name')
                  .eq('id', guardianData['student_id'])
                  .maybeSingle();
              if (studentData != null) {
                invitationData['student_name'] = studentData['name'];
              }
            }
            break;

          case 'general':
            final generalData = await _supabase
                .from('general_invitations')
                .select('name, phone, address')
                .eq('id', inv['reference_id'])
                .maybeSingle();
            if (generalData != null) {
              invitationData.addAll({
                'name': generalData['name'],
                'phone': generalData['phone'],
                'address': generalData['address'],
              });
            }
            break;
        }

        processedInvitations.add(Invitation.fromJson(invitationData));
      }

      _invitations = processedInvitations;
    } catch (e) {
      throw Exception('Gagal memuat undangan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGeneralInvitations() async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, get all general invitations
      final generalInvitationsData = await _supabase
          .from('general_invitations')
          .select('*')
          .order('created_at', ascending: false);

      // Then, get corresponding invitation data
      final generalIds = (generalInvitationsData as List)
          .map((g) => g['id'].toString())
          .toList();

      Map<String, Map<String, dynamic>> invitationsMap = {};

      if (generalIds.isNotEmpty) {
        final invitationsData = await _supabase
            .from('invitations')
            .select('*')
            .eq('invitation_type', 'general')
            .inFilter('reference_id', generalIds);

        // Create a map for easy lookup
        for (var inv in invitationsData) {
          invitationsMap[inv['reference_id']] = inv;
        }
      }

      // Combine the data
      _generalInvitations = generalInvitationsData.map((generalData) {
        final invitation = invitationsMap[generalData['id']];
        return GeneralInvitation.fromJson({
          ...generalData,
          'barcode': invitation?['barcode'],
          'is_checked_in': invitation?['is_checked_in'] ?? false,
        });
      }).toList();
    } catch (e) {
      print('Error loading general invitations: $e');
      throw Exception('Gagal memuat undangan umum: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGeneralInvitation(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get current user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Insert general invitation
      final invitationResponse = await _supabase
          .from('general_invitations')
          .insert({
            'name': data['name'].toString().trim(),
            'address': data['address'].toString().trim(),
            'phone': data['phone'].toString().trim(),
            'created_by': currentUser.id,
          })
          .select()
          .single();

      // Generate barcode
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final barcode = 'GEN-${timestamp.toString().substring(7)}-$random';

      // Create invitation entry
      await _supabase.from('invitations').insert({
        'barcode': barcode,
        'invitation_type': 'general',
        'reference_id': invitationResponse['id'],
      });

      // Reload general invitations
      await loadGeneralInvitations();

      // Refresh dashboard statistics
      _refreshDashboard();
    } catch (e) {
      print('Error in addGeneralInvitation: $e');
      throw Exception('Gagal menambah undangan umum: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> addGeneralInvitationsBulk(
      List<Map<String, String>> invitationsData) async {
    List<String> errors = [];
    int successCount = 0;

    try {
      _isLoading = true;
      notifyListeners();

      // Check authentication
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Silakan login terlebih dahulu');
      }

      for (int i = 0; i < invitationsData.length; i++) {
        final data = invitationsData[i];
        try {
          // Validate data
          if (data['name']?.trim().isEmpty ?? true) {
            errors.add('Baris ${i + 1}: Nama tidak boleh kosong');
            continue;
          }
          if (data['address']?.trim().isEmpty ?? true) {
            errors.add('Baris ${i + 1}: Alamat tidak boleh kosong');
            continue;
          }
          if (data['phone']?.trim().isEmpty ?? true) {
            errors.add('Baris ${i + 1}: No. HP tidak boleh kosong');
            continue;
          }

          // Check for duplicate phone numbers in existing data
          final existingInvitation = await _supabase
              .from('general_invitations')
              .select('id, name')
              .eq('phone', data['phone']!)
              .maybeSingle();

          if (existingInvitation != null) {
            errors.add(
                'Baris ${i + 1}: No. HP ${data['phone']} sudah terdaftar untuk ${existingInvitation['name']}');
            continue;
          }

          // Prepare invitation data
          final invitationData = {
            'name': data['name']!.trim(),
            'address': data['address']!.trim(),
            'phone': data['phone']!.trim(),
            'created_by': currentUser.id,
          };

          // Insert general invitation
          final invitationResponse = await _supabase
              .from('general_invitations')
              .insert(invitationData)
              .select()
              .single();

          // Generate barcode
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final random = (timestamp % 10000).toString().padLeft(4, '0');
          final barcode = 'GEN-${timestamp.toString().substring(7)}-$random';

          // Create invitation entry
          await _supabase.from('invitations').insert({
            'barcode': barcode,
            'invitation_type': 'general',
            'reference_id': invitationResponse['id'],
          });

          successCount++;
        } catch (e) {
          print('Error adding general invitation ${i + 1}: $e');

          if (e is PostgrestException) {
            if (e.code == '23505') {
              errors.add('Baris ${i + 1}: Data sudah ada dalam database');
            } else {
              errors.add('Baris ${i + 1}: Database error - ${e.message}');
            }
          } else {
            errors.add('Baris ${i + 1}: ${e.toString()}');
          }
        }
      }

      // Reload general invitations if any were added successfully
      if (successCount > 0) {
        await loadGeneralInvitations();
        // Refresh dashboard statistics
        _refreshDashboard();
      }

      return errors;
    } catch (e) {
      print('Error in bulk import: $e');
      throw Exception('Error dalam bulk import: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkInByBarcode(String barcode) async {
    try {
      // Get invitation by barcode
      final invitationData = await _supabase
          .from('invitations')
          .select('*')
          .eq('barcode', barcode)
          .single();

      if (invitationData['is_checked_in'] == true) {
        return {
          'success': false,
          'message': 'Undangan ini sudah check-in sebelumnya',
        };
      }

      // Get person details based on type
      Map<String, dynamic> personData = {};
      String type = invitationData['invitation_type'];

      switch (type) {
        case 'student':
          final student = await _supabase
              .from('students')
              .select('name, phone')
              .eq('id', invitationData['reference_id'])
              .single();
          personData = {
            'name': student['name'],
            'phone': student['phone'],
            'type': 'Mahasiswa',
          };
          break;

        case 'guardian':
          final guardian = await _supabase
              .from('guardians')
              .select('name, phone, student_id, person_count')
              .eq('id', invitationData['reference_id'])
              .single();
          final student = await _supabase
              .from('students')
              .select('name')
              .eq('id', guardian['student_id'])
              .single();
          personData = {
            'name': guardian['name'],
            'phone': guardian['phone'],
            'type': 'Wali/Orangtua',
            'student_name': student['name'],
            'person_count': guardian['person_count'] ?? 1,
          };
          break;

        case 'general':
          final general = await _supabase
              .from('general_invitations')
              .select('name, phone')
              .eq('id', invitationData['reference_id'])
              .single();
          personData = {
            'name': general['name'],
            'phone': general['phone'],
            'type': 'Umum',
          };
          break;
      }

      // Update check-in status
      await _supabase.from('invitations').update({
        'is_checked_in': true,
        'checked_in_at': DateTime.now().toIso8601String(),
      }).eq('id', invitationData['id']);

      return {
        'success': true,
        'message': 'Check-in berhasil!',
        'data': personData,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Barcode tidak valid atau tidak ditemukan',
      };
    }
  }

  Future<void> updateGeneralInvitation(
      String id, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Updating general invitation with ID: $id, data: $data');

      // Validate data
      if (data['name'] == null || data['name'].toString().trim().isEmpty) {
        throw Exception('Nama tidak boleh kosong');
      }
      if (data['address'] == null ||
          data['address'].toString().trim().isEmpty) {
        throw Exception('Alamat tidak boleh kosong');
      }
      if (data['phone'] == null || data['phone'].toString().trim().isEmpty) {
        throw Exception('No. HP tidak boleh kosong');
      }

      // Check authentication
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Silakan login terlebih dahulu');
      }

      // Prepare update data
      final updateData = {
        'name': data['name'].toString().trim(),
        'address': data['address'].toString().trim(),
        'phone': data['phone'].toString().trim(),
      };

      print('Updating general invitation data: $updateData');

      // Update general invitation
      await _supabase
          .from('general_invitations')
          .update(updateData)
          .eq('id', id);

      print('General invitation updated successfully');

      // Reload general invitations list
      await loadGeneralInvitations();

      // Refresh dashboard statistics
      _refreshDashboard();
    } catch (e) {
      print('Error updating general invitation: $e');

      // Handle specific Supabase errors
      if (e is PostgrestException) {
        print('Postgrest error code: ${e.code}');
        print('Postgrest error message: ${e.message}');

        if (e.code == '23505') {
          throw Exception('Data sudah ada dalam database');
        } else if (e.code == '23503') {
          throw Exception('Referensi data tidak valid');
        } else {
          throw Exception('Database error: ${e.message}');
        }
      } else if (e is AuthException) {
        throw Exception('Error autentikasi: ${e.message}');
      } else {
        throw Exception(e.toString());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGeneralInvitation(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, explicitly delete the invitation for this general invitation
      await _supabase
          .from('invitations')
          .delete()
          .eq('invitation_type', 'general')
          .eq('reference_id', id);

      // Then delete the general invitation
      await _supabase.from('general_invitations').delete().eq('id', id);

      // Wait briefly for all deletes to complete
      await Future.delayed(const Duration(milliseconds: 500));

      await loadGeneralInvitations();

      // Refresh dashboard statistics after ensuring all deletes complete
      _refreshDashboard();
    } catch (e) {
      throw Exception('Gagal menghapus undangan: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Invitation?> getInvitationByBarcode(String barcode) async {
    try {
      final invitationData = await _supabase
          .from('invitations')
          .select('*')
          .eq('barcode', barcode)
          .single();

      // Get related data based on type
      Map<String, dynamic> completeData = Map.from(invitationData);

      switch (invitationData['invitation_type']) {
        case 'student':
          final student = await _supabase
              .from('students')
              .select('name, phone, address')
              .eq('id', invitationData['reference_id'])
              .single();
          completeData.addAll(student);
          break;

        case 'guardian':
          final guardian = await _supabase
              .from('guardians')
              .select('name, phone, address')
              .eq('id', invitationData['reference_id'])
              .single();
          completeData.addAll(guardian);
          break;

        case 'general':
          final general = await _supabase
              .from('general_invitations')
              .select('name, phone, address')
              .eq('id', invitationData['reference_id'])
              .single();
          completeData.addAll(general);
          break;
      }

      return Invitation.fromJson(completeData);
    } catch (e) {
      return null;
    }
  }
}
