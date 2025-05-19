/// Model class for emergency data
class EmergencyModel {
  final String? id;
  final String userId;
  final String userPhone;
  final String emergencyType;
  final String address;
  final double latitude;
  final double longitude;
  final String status;
  final String? videoId;
  final String createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? additionalInfo;

  EmergencyModel({
    this.id,
    required this.userId,
    required this.userPhone,
    required this.emergencyType,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.videoId,
    required this.createdAt,
    this.updatedAt,
    this.additionalInfo,
  });

  /// Create a model from Firebase Realtime Database
  factory EmergencyModel.fromRealtime(String id, Map<dynamic, dynamic> data) {
    return EmergencyModel(
      id: id,
      userId: data['userId'] ?? '',
      userPhone: data['userPhone'] ?? '',
      emergencyType: data['emergencyType'] ?? 'unknown',
      address: data['address'] ?? '',
      latitude: double.tryParse(data['lat'] ?? '0') ?? 0,
      longitude: double.tryParse(data['long'] ?? '0') ?? 0,
      status: data['status'] ?? 'active',
      videoId: data['videoId'],
      createdAt: data['createdAt'] ?? DateTime.now().toString(),
      updatedAt: data['updatedAt'],
      additionalInfo: data['additionalInfo'] != null
          ? Map<String, dynamic>.from(data['additionalInfo'])
          : null,
    );
  }

  /// Convert model to a map for Firebase Realtime Database
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userPhone': userPhone,
      'emergencyType': emergencyType,
      'address': address,
      'lat': latitude.toString(),
      'long': longitude.toString(),
      'latitude': latitude, // Include both formats for compatibility
      'longitude': longitude,
      'status': status,
      if (videoId != null) 'videoId': videoId,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    };
  }

  /// Create a copy of the model with updated fields
  EmergencyModel copyWith({
    String? id,
    String? userId,
    String? userPhone,
    String? emergencyType,
    String? address,
    double? latitude,
    double? longitude,
    String? status,
    String? videoId,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return EmergencyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userPhone: userPhone ?? this.userPhone,
      emergencyType: emergencyType ?? this.emergencyType,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      videoId: videoId ?? this.videoId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
