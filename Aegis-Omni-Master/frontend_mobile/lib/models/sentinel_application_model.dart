/// Data model for a Sentinel responder application.
/// This is a pure data class — no UI, no StatefulWidget.
/// The UI counterpart lives in screens/sentinel_application_screen.dart
class SentinelApplicationModel {
  final String? id;
  final String name;
  final String cnic;
  final String role;
  final String zone;
  final String experience;
  final String education;
  final String passion;
  final String status;
  final int tier;
  final double? latitude;
  final double? longitude;
  final DateTime? timestamp;

  const SentinelApplicationModel({
    this.id,
    required this.name,
    required this.cnic,
    required this.role,
    required this.zone,
    required this.experience,
    required this.education,
    required this.passion,
    this.status = 'PENDING_VERIFICATION',
    this.tier = 2,
    this.latitude,
    this.longitude,
    this.timestamp,
  });

  /// Deserialize from a Firestore document snapshot map.
  factory SentinelApplicationModel.fromFirestore(
      Map<String, dynamic> data, String docId) {
    return SentinelApplicationModel(
      id: docId,
      name: data['name'] ?? '',
      cnic: data['cnic'] ?? '',
      role: data['role'] ?? '',
      zone: data['zone'] ?? '',
      experience: data['experience'] ?? '',
      education: data['education'] ?? '',
      passion: data['passion'] ?? '',
      status: data['status'] ?? 'PENDING_VERIFICATION',
      tier: data['tier'] ?? 2,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as dynamic).toDate()
          : null,
    );
  }

  /// Serialize to a Firestore-ready map (omits null fields).
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'cnic': cnic,
      'role': role,
      'zone': zone,
      'experience': experience,
      'education': education,
      'passion': passion,
      'status': status,
      'tier': tier,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  /// Returns true if this responder is actively deployed.
  bool get isApproved => status.toLowerCase() == 'approved';

  @override
  String toString() =>
      'SentinelApplicationModel(id: $id, name: $name, status: $status)';
}
