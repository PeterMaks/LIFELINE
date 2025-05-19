import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/services/firebase_service.dart';
import 'package:public_emergency_app/utils/logger_util.dart';

/// A service class for handling all database operations in the app.
/// This centralizes all database access and provides methods for CRUD operations.
class DatabaseService extends GetxService {
  static DatabaseService get instance => Get.find<DatabaseService>();
  
  // Firebase service reference
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  
  // Observable variables to track database status
  final isConnected = false.obs;
  final isInitialized = false.obs;
  
  // Initialize the database service
  Future<DatabaseService> init() async {
    try {
      // Check if Firebase service is available
      if (_firebaseService.isInitialized.value) {
        // Set up database connection listener
        FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
          isConnected.value = event.snapshot.value as bool? ?? false;
          LoggerUtil.info("Database connection status: ${isConnected.value ? 'connected' : 'disconnected'}");
        });
        
        isInitialized.value = true;
        LoggerUtil.info("Database service initialized successfully");
      } else {
        LoggerUtil.error("Firebase service not initialized");
      }
      
      return this;
    } catch (e) {
      LoggerUtil.error("Error initializing database service", e);
      return this;
    }
  }
  
  // USERS OPERATIONS
  
  /// Get user data by ID
  Future<Map<dynamic, dynamic>?> getUserData(String userId) async {
    try {
      if (!isInitialized.value) return null;
      
      final snapshot = await _firebaseService.usersRef.child(userId).get();
      if (snapshot.exists) {
        return snapshot.value as Map<dynamic, dynamic>;
      }
      return null;
    } catch (e) {
      LoggerUtil.error("Error getting user data", e);
      return null;
    }
  }
  
  /// Update user data
  Future<bool> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      if (!isInitialized.value) return false;
      
      await _firebaseService.usersRef.child(userId).update(data);
      LoggerUtil.info("User data updated successfully");
      return true;
    } catch (e) {
      LoggerUtil.error("Error updating user data", e);
      return false;
    }
  }
  
  /// Update user location
  Future<bool> updateUserLocation(String userId, double lat, double long) async {
    try {
      if (!isInitialized.value) return false;
      
      await _firebaseService.usersRef.child(userId).update({
        'location': {
          'latitude': lat,
          'longitude': long,
          'timestamp': DateTime.now().toString(),
        }
      });
      LoggerUtil.info("User location updated successfully");
      return true;
    } catch (e) {
      LoggerUtil.error("Error updating user location", e);
      return false;
    }
  }
  
  // EMERGENCY OPERATIONS
  
  /// Create a new emergency request
  Future<String?> createEmergency(Map<String, dynamic> emergencyData) async {
    try {
      if (!isInitialized.value) return null;
      
      // Add timestamp
      emergencyData['createdAt'] = DateTime.now().toString();
      emergencyData['status'] = 'active';
      
      // Create a new entry with a unique key
      final newRef = _firebaseService.sosRef.push();
      await newRef.set(emergencyData);
      
      LoggerUtil.info("Emergency created with ID: ${newRef.key}");
      return newRef.key;
    } catch (e) {
      LoggerUtil.error("Error creating emergency", e);
      return null;
    }
  }
  
  /// Get active emergencies
  Stream<DatabaseEvent>? getActiveEmergencies() {
    try {
      if (!isInitialized.value) return null;
      
      return _firebaseService.sosRef
          .orderByChild('status')
          .equalTo('active')
          .onValue;
    } catch (e) {
      LoggerUtil.error("Error getting active emergencies", e);
      return null;
    }
  }
  
  /// Update emergency status
  Future<bool> updateEmergencyStatus(String emergencyId, String status) async {
    try {
      if (!isInitialized.value) return false;
      
      await _firebaseService.sosRef.child(emergencyId).update({
        'status': status,
        'updatedAt': DateTime.now().toString(),
      });
      
      LoggerUtil.info("Emergency status updated to: $status");
      return true;
    } catch (e) {
      LoggerUtil.error("Error updating emergency status", e);
      return false;
    }
  }
  
  // RESPONDER OPERATIONS
  
  /// Update responder status (active/inactive)
  Future<bool> updateResponderStatus(
      String responderId, bool isActive, Map<String, dynamic>? locationData) async {
    try {
      if (!isInitialized.value) return false;
      
      if (isActive && locationData != null) {
        // Add timestamp
        locationData['timestamp'] = DateTime.now().toString();
        await _firebaseService.activeRespondersRef.child(responderId).set(locationData);
      } else {
        await _firebaseService.activeRespondersRef.child(responderId).remove();
      }
      
      LoggerUtil.info("Responder status updated: ${isActive ? 'active' : 'inactive'}");
      return true;
    } catch (e) {
      LoggerUtil.error("Error updating responder status", e);
      return false;
    }
  }
  
  /// Get active responders
  Stream<DatabaseEvent>? getActiveResponders() {
    try {
      if (!isInitialized.value) return null;
      
      return _firebaseService.activeRespondersRef.onValue;
    } catch (e) {
      LoggerUtil.error("Error getting active responders", e);
      return null;
    }
  }
  
  /// Assign responder to emergency
  Future<bool> assignResponder(
      String responderId, String emergencyId, Map<String, dynamic> assignmentData) async {
    try {
      if (!isInitialized.value) return false;
      
      // Add timestamp
      assignmentData['assignedAt'] = DateTime.now().toString();
      assignmentData['status'] = 'assigned';
      
      await _firebaseService.assignedRef.child(responderId).set(assignmentData);
      
      // Update emergency status
      await updateEmergencyStatus(emergencyId, 'assigned');
      
      LoggerUtil.info("Responder assigned to emergency");
      return true;
    } catch (e) {
      LoggerUtil.error("Error assigning responder", e);
      return false;
    }
  }
  
  /// Get assigned emergencies for responder
  Stream<DatabaseEvent>? getAssignedEmergencies(String responderId) {
    try {
      if (!isInitialized.value) return null;
      
      return _firebaseService.assignedRef.child(responderId).onValue;
    } catch (e) {
      LoggerUtil.error("Error getting assigned emergencies", e);
      return null;
    }
  }
}
