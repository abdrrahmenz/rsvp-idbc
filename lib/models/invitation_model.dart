class Invitation {
  final String id;
  final String barcode;
  final String invitationType;
  final String referenceId;
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final DateTime createdAt;

  // Additional info from joined tables
  final String? name;
  final String? phone;
  final String? address;
  final String? studentName;
  final int? personCount;

  Invitation({
    required this.id,
    required this.barcode,
    required this.invitationType,
    required this.referenceId,
    required this.isCheckedIn,
    this.checkedInAt,
    required this.createdAt,
    this.name,
    this.phone,
    this.address,
    this.studentName,
    this.personCount,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      barcode: json['barcode'],
      invitationType: json['invitation_type'],
      referenceId: json['reference_id'],
      isCheckedIn: json['is_checked_in'] ?? false,
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      studentName: json['student_name'],
      personCount: json['person_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'invitation_type': invitationType,
      'reference_id': referenceId,
      'is_checked_in': isCheckedIn,
      'checked_in_at': checkedInAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (invitationType) {
      case 'student':
        return 'Mahasiswa';
      case 'guardian':
        return 'Wali/Orangtua';
      case 'general':
        return 'Umum';
      default:
        return 'Unknown';
    }
  }
}
