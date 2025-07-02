class Student {
  final String id;
  final String name;
  final String address;
  final String phone;
  final DateTime createdAt;
  final String? barcode;
  final bool? isCheckedIn;

  Student({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.createdAt,
    this.barcode,
    this.isCheckedIn,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['created_at']),
      barcode: json['barcode'],
      isCheckedIn: json['is_checked_in'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
    };
  }
}