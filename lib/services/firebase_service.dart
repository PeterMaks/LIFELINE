import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/utils/logger_util.dart';
import 'package:public_emergency_app/firebase_options.dart';

class FirebaseService extends GetxService {
  static FirebaseService get instance => Get.find<FirebaseService>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Observable variables
  final Rx<User?> currentUser = Rx<User?>(null);
  final isInitialized = false.obs;

  // Database references
  late final DatabaseReference usersRef;
  late final DatabaseReference sosRef;
  late final DatabaseReference activeRespondersRef;
  late final DatabaseReference assignedRef;

  // Initialize Firebase
  Future<FirebaseService> init() async {
    try {
      // Firebase is already initialized in main.dart

      // Set persistence for offline support
      try {
        // Enable disk persistence for offline support
        _database.setPersistenceEnabled(true);

        // Set cache size to 10MB for better offline performance
        _database.setPersistenceCacheSizeBytes(10 * 1024 * 1024);
      } catch (e) {
        LoggerUtil.error("Error setting persistence", e);
      }

      // Enable logging for debugging
      _database.setLoggingEnabled(true);

      // Initialize database references
      usersRef = _database.ref().child('Users');
      sosRef = _database.ref().child('sos');
      activeRespondersRef = _database.ref().child('activeResponders');
      assignedRef = _database.ref().child('assigned');

      // Configure offline behavior for critical paths
      _configureOfflinePersistence();

      // Set up auth state listener
      _auth.authStateChanges().listen(_onAuthStateChanged);

      // Set up connection state listener
      _database.ref('.info/connected').onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
        LoggerUtil.info(
            "Firebase connection state: ${connected ? 'connected' : 'disconnected'}");
      });

      // Mark as initialized
      isInitialized.value = true;
      LoggerUtil.info("Firebase service initialized successfully");

      return this;
    } catch (e) {
      LoggerUtil.error("Error initializing Firebase service", e);
      rethrow;
    }
  }

  // Configure offline persistence for critical paths
  void _configureOfflinePersistence() {
    try {
      // Keep user data synced offline
      usersRef.keepSynced(true);

      // Keep active emergencies synced offline
      sosRef.orderByChild('status').equalTo('active').keepSynced(true);

      // Keep active responders synced offline
      activeRespondersRef.keepSynced(true);

      // Keep assigned emergencies synced offline
      assignedRef.keepSynced(true);

      LoggerUtil.info("Offline persistence configured successfully");
    } catch (e) {
      LoggerUtil.error("Error configuring offline persistence", e);
    }
  }

  // Auth state change handler
  void _onAuthStateChanged(User? user) {
    currentUser.value = user;
    LoggerUtil.info(
        "Auth state changed: ${user != null ? 'User logged in' : 'User logged out'}");
  }

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get user data from database
  Future<Map<dynamic, dynamic>?> getUserData(String userId) async {
    try {
      final snapshot = await usersRef.child(userId).get();
      if (snapshot.exists) {
        return snapshot.value as Map<dynamic, dynamic>;
      }
      return null;
    } catch (e) {
      LoggerUtil.error("Error getting user data", e);
      return null;
    }
  }

  // Save user data to database
  Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    try {
      await usersRef.child(userId).update(data);
      LoggerUtil.info("User data saved successfully");
    } catch (e) {
      LoggerUtil.error("Error saving user data", e);
      rethrow;
    }
  }

  // Create SOS request
  Future<String?> createSosRequest(Map<String, dynamic> sosData) async {
    try {
      final newRef = sosRef.push();
      await newRef.set(sosData);
      LoggerUtil.info("SOS request created with ID: ${newRef.key}");
      return newRef.key;
    } catch (e) {
      LoggerUtil.error("Error creating SOS request", e);
      return null;
    }
  }

  // Update responder status
  Future<void> updateResponderStatus(String responderId, bool isActive,
      Map<String, dynamic>? locationData) async {
    try {
      if (isActive && locationData != null) {
        await activeRespondersRef.child(responderId).set(locationData);
      } else {
        await activeRespondersRef.child(responderId).remove();
      }
      LoggerUtil.info(
          "Responder status updated: ${isActive ? 'active' : 'inactive'}");
    } catch (e) {
      LoggerUtil.error("Error updating responder status", e);
      rethrow;
    }
  }

  // Assign responder to emergency
  Future<void> assignResponder(String responderId, String emergencyId,
      Map<String, dynamic> assignmentData) async {
    try {
      await assignedRef.child(responderId).set(assignmentData);
      LoggerUtil.info("Responder assigned to emergency");
    } catch (e) {
      LoggerUtil.error("Error assigning responder", e);
      rethrow;
    }
  }

  // Get active emergencies stream
  Stream<DatabaseEvent> getActiveEmergenciesStream() {
    return sosRef.onValue;
  }

  // Get active responders stream
  Stream<DatabaseEvent> getActiveRespondersStream() {
    return activeRespondersRef.onValue;
  }

  // Get assigned emergencies for responder
  Stream<DatabaseEvent> getAssignedEmergenciesStream(String responderId) {
    return assignedRef.child(responderId).onValue;
  }
}
