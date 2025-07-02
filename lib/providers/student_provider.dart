import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';
import '../models/guardian_model.dart';
import 'dashboard_provider.dart';

class StudentProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Student> _students = [];
  List<Guardian> _guardians = [];
  bool _isLoading = false;
  DashboardProvider? _dashboardProvider;

  List<Student> get students => _students;
  List<Guardian> get guardians => _guardians;
  bool get isLoading => _isLoading;

  // Set dashboard provider for automatic refresh
  void setDashboardProvider(DashboardProvider? dashboardProvider) {
    _dashboardProvider = dashboardProvider;
  }

  // Helper method to refresh dashboard statistics
  void _refreshDashboard() {
    _dashboardProvider?.refreshStatistics();
  }

  Future<void> loadStudents() async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, get all students
      final studentsResponse = await _supabase
          .from('students')
          .select('*')
          .order('created_at', ascending: false);

      // Then, get all invitations for students
      final invitationsResponse = await _supabase
          .from('invitations')
          .select('*')
          .eq('invitation_type', 'student');

      // Create a map of invitations by reference_id
      final invitationsMap = <String, Map<String, dynamic>>{};
      for (final inv in invitationsResponse as List) {
        invitationsMap[inv['reference_id']] = inv;
      }

      // Combine the data
      _students = (studentsResponse as List).map((studentJson) {
        final invitation = invitationsMap[studentJson['id']];
        return Student.fromJson({
          ...studentJson,
          'barcode': invitation?['barcode'],
          'is_checked_in': invitation?['is_checked_in'] ?? false,
        });
      }).toList();
    } catch (e) {
      print('Error loading students: $e');
      print('Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('Postgrest error code: ${e.code}');
        print('Postgrest error message: ${e.message}');
        print('Postgrest error details: ${e.details}');
      }
      throw Exception('Gagal memuat data mahasiswa: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addStudent(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Adding student with data: $data');

      // Validate data
      if (data['name'] == null || data['name'].toString().trim().isEmpty) {
        throw Exception('Nama mahasiswa tidak boleh kosong');
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

      // Prepare student data
      final studentData = {
        'name': data['name'].toString().trim(),
        'address': data['address'].toString().trim(),
        'phone': data['phone'].toString().trim(),
        'created_by': currentUser.id,
      };

      print('Inserting student data: $studentData');

      // Insert student
      final studentResponse = await _supabase
          .from('students')
          .insert(studentData)
          .select()
          .single();

      print('Student created with ID: ${studentResponse['id']}');

      // Generate barcode using RPC function
      final barcodeResponse = await _supabase
          .rpc('generate_unique_barcode', params: {'prefix': 'STD'});

      final barcode = barcodeResponse.toString();
      print('Generated barcode: $barcode');

      // Create invitation
      final invitationData = {
        'barcode': barcode,
        'invitation_type': 'student',
        'reference_id': studentResponse['id'],
      };

      await _supabase.from('invitations').insert(invitationData);

      print('Invitation created successfully');

      // Reload students list
      await loadStudents();

      // Refresh dashboard statistics
      _refreshDashboard();
    } catch (e) {
      print('Error in addStudent: $e');
      print('Error type: ${e.runtimeType}');
      print('Data being inserted: $data');

      // Handle specific Supabase errors
      if (e is PostgrestException) {
        print('Postgrest error code: ${e.code}');
        print('Postgrest error message: ${e.message}');
        print('Postgrest error details: ${e.details}');
        print('Postgrest error hint: ${e.hint}');

        if (e.code == '23505') {
          // Unique constraint violation
          throw Exception('Data sudah ada dalam database');
        } else if (e.code == '23503') {
          // Foreign key violation
          throw Exception('Referensi data tidak valid');
        } else {
          throw Exception('Database error: ${e.message}');
        }
      } else if (e is AuthException) {
        print('Auth error: ${e.message}');
        throw Exception('Authentication error: ${e.message}');
      } else {
        print('General error: $e');
        throw Exception(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStudent(
      String studentId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Updating student with ID: $studentId, data: $data');

      // Validate data
      if (data['name'] == null || data['name'].toString().trim().isEmpty) {
        throw Exception('Nama mahasiswa tidak boleh kosong');
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
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Updating student data: $updateData');

      // Update student
      await _supabase.from('students').update(updateData).eq('id', studentId);

      print('Student updated successfully');

      // Reload students list
      await loadStudents();

      // Refresh dashboard statistics
      _refreshDashboard();
    } catch (e) {
      print('Error updating student: $e');

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
        print('Auth error: ${e.message}');
        throw Exception('Authentication error: ${e.message}');
      } else {
        throw Exception('Gagal memperbarui data mahasiswa: ${e.toString()}');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> addStudentsBulk(
      List<Map<String, String>> studentsData) async {
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

      for (int i = 0; i < studentsData.length; i++) {
        final data = studentsData[i];
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
          final existingStudent = await _supabase
              .from('students')
              .select('id, name')
              .eq('phone', data['phone']!)
              .maybeSingle();

          if (existingStudent != null) {
            errors.add(
                'Baris ${i + 1}: No. HP ${data['phone']} sudah terdaftar untuk ${existingStudent['name']}');
            continue;
          }

          // Prepare student data
          final studentData = {
            'name': data['name']!.trim(),
            'address': data['address']!.trim(),
            'phone': data['phone']!.trim(),
            'created_by': currentUser.id,
          };

          // Insert student
          final studentResponse = await _supabase
              .from('students')
              .insert(studentData)
              .select()
              .single();

          // Generate barcode using RPC function
          final barcodeResponse = await _supabase
              .rpc('generate_unique_barcode', params: {'prefix': 'STD'});

          final barcode = barcodeResponse.toString();

          // Create invitation
          final invitationData = {
            'barcode': barcode,
            'invitation_type': 'student',
            'reference_id': studentResponse['id'],
          };

          await _supabase.from('invitations').insert(invitationData);
          successCount++;
        } catch (e) {
          print('Error adding student ${i + 1}: $e');

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

      // Reload students list if any were added successfully
      if (successCount > 0) {
        await loadStudents();
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

  Future<void> loadGuardians(String studentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, get guardians for the student
      final guardiansResponse = await _supabase
          .from('guardians')
          .select('*')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      // Get guardian IDs
      final guardianIds =
          (guardiansResponse as List).map((g) => g['id'].toString()).toList();

      // Initialize empty invitations map
      Map<String, Map<String, dynamic>> invitationsMap = {};

      // Only query invitations if there are guardians
      if (guardianIds.isNotEmpty) {
        final invitationsResponse = await _supabase
            .from('invitations')
            .select('*')
            .eq('invitation_type', 'guardian')
            .inFilter('reference_id', guardianIds);

        // Create invitations map for easy lookup
        for (final inv in invitationsResponse as List) {
          invitationsMap[inv['reference_id']] = inv;
        }
      }

      // Get student name
      final studentResponse = await _supabase
          .from('students')
          .select('name')
          .eq('id', studentId)
          .maybeSingle();

      final studentName = studentResponse?['name'] ?? 'Unknown Student';

      // Combine guardian data with invitation data
      _guardians = guardiansResponse.map((guardianJson) {
        final invitation = invitationsMap[guardianJson['id']];
        return Guardian.fromJson({
          ...guardianJson,
          'student_name': studentName,
          'barcode': invitation?['barcode'],
          'is_checked_in': invitation?['is_checked_in'] ?? false,
        });
      }).toList();

      print('Loaded ${_guardians.length} guardians for student $studentId');
    } catch (e) {
      print('Error loading guardians: $e');
      throw Exception('Gagal memuat data wali: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGuardian(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get current user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check existing guardians count
      final existingGuardians = await _supabase
          .from('guardians')
          .select('id')
          .eq('student_id', data['student_id']);

      if ((existingGuardians as List).length >= 3) {
        throw Exception('Mahasiswa sudah memiliki 3 wali');
      }

      // Insert guardian with created_by
      final guardianResponse = await _supabase
          .from('guardians')
          .insert({
            'student_id': data['student_id'],
            'name': data['name'].toString().trim(),
            'address': data['address'].toString().trim(),
            'phone': data['phone'].toString().trim(),
            'person_count': data['person_count'] ?? 1,
            'created_by': currentUser.id, // Add this line
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Generate barcode
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = (timestamp % 10000).toString().padLeft(4, '0');
      final barcode =
          'GRD-${guardianResponse['id'].toString().substring(0, 8).toUpperCase()}-$random';

      // Create invitation
      await _supabase.from('invitations').insert({
        'barcode': barcode,
        'invitation_type': 'guardian',
        'reference_id': guardianResponse['id'],
        'created_at': DateTime.now().toIso8601String(),
      });

      // Reload guardians
      await loadGuardians(data['student_id']);

      // Refresh dashboard statistics
      _refreshDashboard();
    } catch (e) {
      print('Error in addGuardian: $e');
      throw Exception('Database error: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String studentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, explicitly delete all related invitations for this student
      await _supabase
          .from('invitations')
          .delete()
          .eq('invitation_type', 'student')
          .eq('reference_id', studentId);

      // Delete all guardians related to this student (this will also delete guardian invitations)
      final guardians = await _supabase
          .from('guardians')
          .select('id')
          .eq('student_id', studentId);

      for (final guardian in guardians) {
        await _supabase
            .from('invitations')
            .delete()
            .eq('invitation_type', 'guardian')
            .eq('reference_id', guardian['id']);
      }

      // Delete guardians for this student
      await _supabase.from('guardians').delete().eq('student_id', studentId);

      // Finally, delete the student
      await _supabase.from('students').delete().eq('id', studentId);

      // Wait briefly for all deletes to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload students list
      await loadStudents();

      // Refresh dashboard statistics after ensuring all deletes complete
      _refreshDashboard();
    } catch (e) {
      print('Error deleting student: $e');
      throw Exception('Gagal menghapus mahasiswa: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteStudents(List<String> studentIds) async {
    try {
      _isLoading = true;
      notifyListeners();

      // For each student, delete related invitations and guardians first
      for (final studentId in studentIds) {
        // Delete all student invitations
        await _supabase
            .from('invitations')
            .delete()
            .eq('invitation_type', 'student')
            .eq('reference_id', studentId);

        // Delete all guardian invitations for this student
        final guardians = await _supabase
            .from('guardians')
            .select('id')
            .eq('student_id', studentId);

        for (final guardian in guardians) {
          await _supabase
              .from('invitations')
              .delete()
              .eq('invitation_type', 'guardian')
              .eq('reference_id', guardian['id']);
        }

        // Delete guardians for this student
        await _supabase.from('guardians').delete().eq('student_id', studentId);
      }

      // Finally, delete all students
      await _supabase.from('students').delete().inFilter('id', studentIds);

      // Wait briefly for all deletes to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload students list
      await loadStudents();

      // Refresh dashboard statistics after ensuring all deletes complete
      _refreshDashboard();
    } catch (e) {
      print('Error deleting students: $e');
      throw Exception('Gagal menghapus mahasiswa: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGuardian(String guardianId, String studentId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // First, explicitly delete the invitation for this guardian
      await _supabase
          .from('invitations')
          .delete()
          .eq('invitation_type', 'guardian')
          .eq('reference_id', guardianId);

      // Then delete the guardian
      await _supabase.from('guardians').delete().eq('id', guardianId);

      // Wait briefly for all deletes to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload guardians for the student
      await loadGuardians(studentId);

      // Refresh dashboard statistics after ensuring all deletes complete
      _refreshDashboard();
    } catch (e) {
      print('Error deleting guardian: $e');
      throw Exception('Gagal menghapus wali: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGuardian(
      String guardianId, String studentId, Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Validate data
      if (data['name'] == null || data['name'].toString().trim().isEmpty) {
        throw Exception('Nama wali tidak boleh kosong');
      }
      if (data['address'] == null ||
          data['address'].toString().trim().isEmpty) {
        throw Exception('Alamat tidak boleh kosong');
      }
      if (data['phone'] == null || data['phone'].toString().trim().isEmpty) {
        throw Exception('No. HP tidak boleh kosong');
      }

      // Prepare update data
      final updateData = {
        'name': data['name'].toString().trim(),
        'address': data['address'].toString().trim(),
        'phone': data['phone'].toString().trim(),
        'person_count': data['person_count'] ?? 1,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Update guardian
      await _supabase.from('guardians').update(updateData).eq('id', guardianId);

      // Reload guardians for the student
      await loadGuardians(studentId);

      // Refresh dashboard statistics
      _refreshDashboard();
    } catch (e) {
      print('Error updating guardian: $e');
      throw Exception('Gagal memperbarui data wali: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
