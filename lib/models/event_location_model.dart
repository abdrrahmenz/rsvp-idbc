class EventLocation {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final DateTime eventDate;
  final DateTime updatedAt;

  EventLocation({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    required this.eventDate,
    required this.updatedAt,
  });

  factory EventLocation.fromJson(Map<String, dynamic> json) {
    return EventLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      eventDate: DateTime.parse(json['event_date']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'event_date': eventDate.toIso8601String(),
    };
  }

  String get googleMapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
  }
}