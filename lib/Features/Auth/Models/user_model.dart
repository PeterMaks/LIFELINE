import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String userType;
  final String? profileImageUrl;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final GeoPoint? location;
  final List<String>? emergencyContacts;
  final Map<String, dynamic>? medicalInfo;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    this.profileImageUrl,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.location,
    this.emergencyContacts,
    this.medicalInfo,
  });

  // Convert model to JSON for storing in Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'profileImageUrl': profileImageUrl,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'location': location,
      'emergencyContacts': emergencyContacts,
      'medicalInfo': medicalInfo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create model from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      userType: data['userType'] ?? 'civilian',
      profileImageUrl: data['profileImageUrl'],
      address: data['address'],
      city: data['city'],
      state: data['state'],
      country: data['country'],
      zipCode: data['zipCode'],
      location: data['location'],
      emergencyContacts: data['emergencyContacts'] != null 
          ? List<String>.from(data['emergencyContacts']) 
          : null,
      medicalInfo: data['medicalInfo'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Create a copy of the model with updated fields
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? userType,
    String? profileImageUrl,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    GeoPoint? location,
    List<String>? emergencyContacts,
    Map<String, dynamic>? medicalInfo,
    Timestamp? updatedAt,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      location: location ?? this.location,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      medicalInfo: medicalInfo ?? this.medicalInfo,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? Timestamp.now(),
    );
  }
}
