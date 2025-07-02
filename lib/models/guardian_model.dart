class Guardian {
  final String id;
  final String studentId;
  final String name;
  final String address;
  final String phone;
  final int personCount;
  final DateTime createdAt;
  final String? studentName;
  final String? barcode;
  final bool? isCheckedIn;

  Guardian({
    required this.id,
    required this.studentId,
    required this.name,
    required this.address,
    required this.phone,
    required this.personCount,
    required this.createdAt,
    this.studentName,
    this.barcode,
    this.isCheckedIn,
  });

  factory Guardian.fromJson(Map<String, dynamic> json) {
    return Guardian(
      id: json['id'],
      studentId: json['student_id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      personCount: json['person_count'] ?? 1,
      createdAt: DateTime.parse(json['created_at']),
      studentName: json['student_name'],
      barcode: json['barcode'],
      isCheckedIn: json['is_checked_in'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'name': name,
      'address': address,
      'phone': phone,
      'person_count': personCount,
    };
  }
}
