import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic> _statistics = {
    'total_students': 0,
    'total_guardians': 0,
    'total_general': 0,
    'total_invitations': 0,
    'total_checked_in': 0,
    'check_in_percentage': 0.0,
  };
  bool _isLoading = false;

  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;

  Future<void> loadStatistics() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Always calculate from source tables to ensure real-time accuracy
      // This ensures statistics are always up-to-date when data changes
      await _calculateStatisticsManually();
    } catch (e) {
      print('Error loading statistics: $e');
      // Fallback to basic counting if detailed calculation fails
      await _fallbackStatisticsCalculation();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _calculateStatisticsManually() async {
    try {
      print(
          'Calculating statistics from source tables for real-time accuracy...');

      // Get actual counts from each source table - using simple select approach for reliability
      final studentsData = await _supabase.from('students').select('id');
      final guardiansData = await _supabase.from('guardians').select('id');
      final generalData =
          await _supabase.from('general_invitations').select('id');

      // Get check-in statistics from invitations table with additional fields for debugging
      final allInvitations = await _supabase.from('invitations').select(
          'invitation_type, is_checked_in, reference_id, checked_in_at');

      final studentsCount = studentsData.length;
      final guardiansCount = guardiansData.length;
      final generalCount = generalData.length;

      print('Raw counts from database:');
      print('  Students: $studentsCount');
      print('  Guardians: $guardiansCount');
      print('  General: $generalCount');
      print('  Invitations: ${allInvitations.length}');

      int totalCheckedIn = 0;
      int totalStudentInvitations = 0;
      int totalGuardianInvitations = 0;
      int totalGeneralInvitations = 0;

      // Count invitations by type and check-in status
      for (final inv in allInvitations) {
        if (inv['is_checked_in'] == true) {
          totalCheckedIn++;
        }

        switch (inv['invitation_type']) {
          case 'student':
            totalStudentInvitations++;
            break;
          case 'guardian':
            totalGuardianInvitations++;
            break;
          case 'general':
            totalGeneralInvitations++;
            break;
        }
      }

      final totalInvitations = allInvitations.length;
      final percentage = totalInvitations > 0
          ? (totalCheckedIn / totalInvitations * 100).toStringAsFixed(1)
          : '0.0';

      _statistics = {
        'total_students': studentsCount,
        'total_guardians': guardiansCount,
        'total_general': generalCount,
        'total_invitations': totalInvitations,
        'total_checked_in': totalCheckedIn,
        'check_in_percentage': double.parse(percentage),
        // Additional debugging info
        'source_counts': {
          'students_in_db': studentsCount,
          'guardians_in_db': guardiansCount,
          'general_in_db': generalCount,
        },
        'invitation_breakdown': {
          'student_invitations': totalStudentInvitations,
          'guardian_invitations': totalGuardianInvitations,
          'general_invitations': totalGeneralInvitations,
        }
      };

      print('=== DASHBOARD STATISTICS DEBUG ===');
      print('Students: $studentsCount (invitations: $totalStudentInvitations)');
      print(
          'Guardians: $guardiansCount (invitations: $totalGuardianInvitations)');
      print('General: $generalCount (invitations: $totalGeneralInvitations)');
      print(
          'Total invitations: $totalInvitations, Checked in: $totalCheckedIn');
      print('Check-in percentage: ${percentage}%');

      // Debug: Show details of checked-in invitations
      final checkedInInvitations =
          allInvitations.where((inv) => inv['is_checked_in'] == true).toList();
      print(
          'DEBUG: Found ${checkedInInvitations.length} checked-in invitations:');
      for (final inv in checkedInInvitations) {
        print(
            '  - Type: ${inv['invitation_type']}, Ref ID: ${inv['reference_id']}, Checked in at: ${inv['checked_in_at']}');
      }
      print('=================================');

      // Check for data inconsistencies and warn if found
      if (studentsCount != totalStudentInvitations) {
        print(
            'WARNING: Student count mismatch - DB: $studentsCount, Invitations: $totalStudentInvitations');
      }
      if (guardiansCount != totalGuardianInvitations) {
        print(
            'WARNING: Guardian count mismatch - DB: $guardiansCount, Invitations: $totalGuardianInvitations');
      }
      if (generalCount != totalGeneralInvitations) {
        print(
            'WARNING: General count mismatch - DB: $generalCount, Invitations: $totalGeneralInvitations');
      }
    } catch (e) {
      debugPrint('Error calculating statistics: $e');
      // Fallback to basic counting if detailed calculation fails
      await _fallbackStatisticsCalculation();
    }
  }

  Future<void> _fallbackStatisticsCalculation() async {
    try {
      print('Using fallback statistics calculation...');
      // Simple fallback calculation from invitations table only
      final invitations = await _supabase
          .from('invitations')
          .select('invitation_type, is_checked_in');

      int totalStudents = 0;
      int totalGuardians = 0;
      int totalGeneral = 0;
      int totalCheckedIn = 0;

      for (final inv in invitations) {
        switch (inv['invitation_type']) {
          case 'student':
            totalStudents++;
            break;
          case 'guardian':
            totalGuardians++;
            break;
          case 'general':
            totalGeneral++;
            break;
        }

        if (inv['is_checked_in'] == true) {
          totalCheckedIn++;
        }
      }

      final totalInvitations = invitations.length;
      final percentage = totalInvitations > 0
          ? (totalCheckedIn / totalInvitations * 100).toStringAsFixed(1)
          : '0.0';

      _statistics = {
        'total_students': totalStudents,
        'total_guardians': totalGuardians,
        'total_general': totalGeneral,
        'total_invitations': totalInvitations,
        'total_checked_in': totalCheckedIn,
        'check_in_percentage': double.parse(percentage),
      };

      print('Fallback statistics calculated:');
      print(
          'Total invitations: $totalInvitations, Checked in: $totalCheckedIn, Percentage: ${percentage}%');
    } catch (e) {
      debugPrint('Error in fallback calculation: $e');
    }
  }

  // Method to clean up orphaned invitations (invitations without valid reference)
  Future<void> cleanupOrphanedInvitations() async {
    try {
      print('Cleaning up orphaned invitations...');

      // Get all invitations
      final allInvitations = await _supabase
          .from('invitations')
          .select('id, invitation_type, reference_id');

      final orphanedIds = <String>[];

      for (final invitation in allInvitations) {
        final type = invitation['invitation_type'];
        final refId = invitation['reference_id'];
        final invitationId = invitation['id'];

        bool isOrphaned = false;

        // Check if the referenced record still exists
        switch (type) {
          case 'student':
            final studentExists = await _supabase
                .from('students')
                .select('id')
                .eq('id', refId)
                .maybeSingle();
            if (studentExists == null) isOrphaned = true;
            break;
          case 'guardian':
            final guardianExists = await _supabase
                .from('guardians')
                .select('id')
                .eq('id', refId)
                .maybeSingle();
            if (guardianExists == null) isOrphaned = true;
            break;
          case 'general':
            final generalExists = await _supabase
                .from('general_invitations')
                .select('id')
                .eq('id', refId)
                .maybeSingle();
            if (generalExists == null) isOrphaned = true;
            break;
        }

        if (isOrphaned) {
          orphanedIds.add(invitationId);
          print(
              'Found orphaned invitation: $invitationId (type: $type, ref: $refId)');
        }
      }

      // Delete orphaned invitations
      if (orphanedIds.isNotEmpty) {
        await _supabase
            .from('invitations')
            .delete()
            .inFilter('id', orphanedIds);
        print('Cleaned up ${orphanedIds.length} orphaned invitations');
      } else {
        print('No orphaned invitations found');
      }
    } catch (e) {
      print('Error cleaning up orphaned invitations: $e');
    }
  }

  // Method to force refresh statistics (called after data changes)
  // This is the key method that ensures dashboard updates when data changes
  Future<void> refreshStatistics() async {
    print('Refreshing dashboard statistics after data changes...');

    // Clean up any orphaned invitations first
    await cleanupOrphanedInvitations();

    // Add a delay to ensure database operations complete
    await Future.delayed(const Duration(milliseconds: 800));

    // Force a complete reload of statistics
    await loadStatistics();

    // Double-check with a second refresh if there were inconsistencies
    final stats = _statistics;
    final studentsInDb = stats['source_counts']?['students_in_db'] ?? 0;
    final studentsInInvitations =
        stats['invitation_breakdown']?['student_invitations'] ?? 0;
    final guardiansInDb = stats['source_counts']?['guardians_in_db'] ?? 0;
    final guardiansInInvitations =
        stats['invitation_breakdown']?['guardian_invitations'] ?? 0;
    final generalInDb = stats['source_counts']?['general_in_db'] ?? 0;
    final generalInInvitations =
        stats['invitation_breakdown']?['general_invitations'] ?? 0;

    // If there are still mismatches, wait a bit more and try again
    if (studentsInDb != studentsInInvitations ||
        guardiansInDb != guardiansInInvitations ||
        generalInDb != generalInInvitations) {
      print(
          'Data inconsistency detected after cleanup, performing additional refresh...');
      await Future.delayed(const Duration(milliseconds: 500));
      await loadStatistics();
    }
  }

  // Method to reset statistics (useful for testing or clearing cache)
  void resetStatistics() {
    _statistics = {
      'total_students': 0,
      'total_guardians': 0,
      'total_general': 0,
      'total_invitations': 0,
      'total_checked_in': 0,
      'check_in_percentage': 0.0,
    };
    notifyListeners();
  }

  Future<Map<String, dynamic>> getDetailedStatistics() async {
    try {
      // Get recent check-ins
      final recentCheckIns = await _supabase
          .from('invitations')
          .select('''
            *,
            students!invitations_reference_id_fkey(name),
            guardians!invitations_reference_id_fkey(name),
            general_invitations!invitations_reference_id_fkey(name)
          ''')
          .eq('is_checked_in', true)
          .order('checked_in_at', ascending: false)
          .limit(10);

      // Get check-ins by hour for today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todayCheckIns = await _supabase
          .from('invitations')
          .select('checked_in_at')
          .eq('is_checked_in', true)
          .gte('checked_in_at', startOfDay.toIso8601String());

      return {
        'basic': _statistics,
        'recentCheckIns': recentCheckIns,
        'todayCheckIns': todayCheckIns,
      };
    } catch (e) {
      throw Exception('Gagal memuat statistik detail: $e');
    }
  }

  // Method to manually cleanup database inconsistencies
  Future<void> manualDatabaseCleanup() async {
    try {
      print('Starting manual database cleanup...');

      // Clean up orphaned invitations
      await cleanupOrphanedInvitations();

      // Also clean up orphaned guardians (guardians whose students don't exist)
      final allGuardians =
          await _supabase.from('guardians').select('id, student_id');

      final orphanedGuardianIds = <String>[];

      for (final guardian in allGuardians) {
        final studentExists = await _supabase
            .from('students')
            .select('id')
            .eq('id', guardian['student_id'])
            .maybeSingle();

        if (studentExists == null) {
          orphanedGuardianIds.add(guardian['id']);
          print(
              'Found orphaned guardian: ${guardian['id']} (student: ${guardian['student_id']})');
        }
      }

      // Delete orphaned guardians and their invitations
      if (orphanedGuardianIds.isNotEmpty) {
        // Delete guardian invitations first
        for (final guardianId in orphanedGuardianIds) {
          await _supabase
              .from('invitations')
              .delete()
              .eq('invitation_type', 'guardian')
              .eq('reference_id', guardianId);
        }

        // Delete the orphaned guardians
        await _supabase
            .from('guardians')
            .delete()
            .inFilter('id', orphanedGuardianIds);

        print('Cleaned up ${orphanedGuardianIds.length} orphaned guardians');
      }

      print('Manual database cleanup completed');

      // Refresh statistics after cleanup
      await loadStatistics();
    } catch (e) {
      print('Error during manual database cleanup: $e');
    }
  }
}
