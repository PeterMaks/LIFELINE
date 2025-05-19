/// Model class for responder data
class ResponderModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String responderType; // ambulance, police, firefighter
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final String? deviceId;
  final String? lastSeen;
  final Map<String, dynamic>? additionalInfo;

  ResponderModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.responderType,
    required this.isActive,
    this.latitude,
    this.longitude,
    this.deviceId,
    this.lastSeen,
    this.additionalInfo,
  });

  /// Create a model from Firebase Realtime Database
  factory ResponderModel.fromRealtime(String id, Map<dynamic, dynamic> data) {
    return ResponderModel(
      id: id,
      name: data['UserName'] ?? '',
      phone: data['Phone'] ?? '',
      email: data['email'] ?? '',
      responderType: data['responderType'] ?? 'unknown',
      isActive: data['isActive'] ?? false,
      latitude: data['lat'] != null ? double.tryParse(data['lat']) : null,
      longitude: data['long'] != null ? double.tryParse(data['long']) : null,
      deviceId: data['deviceId'],
      lastSeen: data['lastSeen'],
      additionalInfo: data['additionalInfo'] != null
          ? Map<String, dynamic>.from(data['additionalInfo'])
          : null,
    );
  }

  /// Create a model from active responders data
  factory ResponderModel.fromActiveResponder(String id, Map<dynamic, dynamic> data) {
    return ResponderModel(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      responderType: data['responderType'] ?? 'unknown',
      isActive: true,
      latitude: data['lat'] != null ? double.tryParse(data['lat']) : null,
      longitude: data['long'] != null ? double.tryParse(data['long']) : null,
      deviceId: data['deviceId'],
      lastSeen: data['timestamp'],
      additionalInfo: null,
    );
  }

  /// Convert model to a map for Firebase Realtime Database
  Map<String, dynamic> toMap() {
    return {
      'UserName': name,
      'Phone': phone,
      'email': email,
      'responderType': responderType,
      'isActive': isActive,
      if (latitude != null) 'lat': latitude.toString(),
      if (longitude != null) 'long': longitude.toString(),
      if (deviceId != null) 'deviceId': deviceId,
      if (lastSeen != null) 'lastSeen': lastSeen,
      if (additionalInfo != null) 'additionalInfo': additionalInfo,
    };
  }

  /// Convert model to a map for active responders
  Map<String, dynamic> toActiveMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'responderType': responderType,
      'lat': latitude?.toString() ?? '0',
      'long': longitude?.toString() ?? '0',
      'deviceId': deviceId,
      'timestamp': DateTime.now().toString(),
    };
  }

  /// Create a copy of the model with updated fields
  ResponderModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? responderType,
    bool? isActive,
    double? latitude,
    double? longitude,
    String? deviceId,
    String? lastSeen,
    Map<String, dynamic>? additionalInfo,
  }) {
    return ResponderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      responderType: responderType ?? this.responderType,
      isActive: isActive ?? this.isActive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      deviceId: deviceId ?? this.deviceId,
      lastSeen: lastSeen ?? this.lastSeen,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
