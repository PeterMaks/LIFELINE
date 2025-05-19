import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/Auth/Models/user_model.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Collection reference
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('users');

  // Create a new user in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      // Set the document with the user's UID as the document ID
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      print("Error creating user: $e");
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      
      if (docSnapshot.exists) {
        return UserModel.fromFirestore(
            docSnapshot as DocumentSnapshot<Map<String, dynamic>>);
      }
      return null;
    } catch (e) {
      print("Error getting user: $e");
      rethrow;
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    
    return getUserById(currentUser.uid);
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).update({
        'name': user.name,
        'phone': user.phone,
        'userType': user.userType,
        'profileImageUrl': user.profileImageUrl,
        'address': user.address,
        'city': user.city,
        'state': user.state,
        'country': user.country,
        'zipCode': user.zipCode,
        'location': user.location,
        'emergencyContacts': user.emergencyContacts,
        'medicalInfo': user.medicalInfo,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print("Error updating user: $e");
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      print("Error deleting user: $e");
      rethrow;
    }
  }

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print("Error getting all users: $e");
      rethrow;
    }
  }

  // Get users by type
  Future<List<UserModel>> getUsersByType(String userType) async {
    try {
      final querySnapshot = await _usersCollection
          .where('userType', isEqualTo: userType)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print("Error getting users by type: $e");
      rethrow;
    }
  }

  // Update emergency contacts
  Future<void> updateEmergencyContacts(String userId, List<String> contacts) async {
    try {
      await _usersCollection.doc(userId).update({
        'emergencyContacts': contacts,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print("Error updating emergency contacts: $e");
      rethrow;
    }
  }

  // Update medical information
  Future<void> updateMedicalInfo(String userId, Map<String, dynamic> medicalInfo) async {
    try {
      await _usersCollection.doc(userId).update({
        'medicalInfo': medicalInfo,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print("Error updating medical info: $e");
      rethrow;
    }
  }

  // Update user location
  Future<void> updateUserLocation(String userId, GeoPoint location) async {
    try {
      await _usersCollection.doc(userId).update({
        'location': location,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print("Error updating user location: $e");
      rethrow;
    }
  }
}
