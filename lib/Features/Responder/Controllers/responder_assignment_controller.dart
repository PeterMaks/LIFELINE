import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/Auth/Controllers/auth_controller.dart';
import 'package:public_emergency_app/models/emergency_model.dart';
import 'package:public_emergency_app/models/responder_model.dart';
import 'package:public_emergency_app/services/database_service.dart';
import 'package:public_emergency_app/services/firebase_service.dart';
import 'package:public_emergency_app/utils/logger_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResponderAssignmentController extends GetxController {
  static ResponderAssignmentController get instance => Get.find();

  // Dependencies
  late final DatabaseService _databaseService;
  late final FirebaseService _firebaseService;
  late final AuthController _authController;

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isAssigning = false.obs;
  final RxList<EmergencyModel> activeEmergencies = <EmergencyModel>[].obs;
  final RxList<ResponderModel> activeResponders = <ResponderModel>[].obs;
  final RxMap<String, String> assignedEmergencies = <String, String>{}.obs;

  // Current responder info
  final Rx<String> responderId = ''.obs;
  final Rx<String> responderType = ''.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);

  @override
  void onInit() {
    super.onInit();

    // Safely initialize dependencies
    try {
      _databaseService = Get.find<DatabaseService>();
    } catch (e) {
      LoggerUtil.error('Error finding DatabaseService', e);
      Get.put(DatabaseService());
      _databaseService = Get.find<DatabaseService>();
    }

    try {
      _firebaseService = Get.find<FirebaseService>();
    } catch (e) {
      LoggerUtil.error('Error finding FirebaseService', e);
      Get.put(FirebaseService());
      _firebaseService = Get.find<FirebaseService>();
    }

    try {
      _authController = Get.find<AuthController>();
    } catch (e) {
      LoggerUtil.error('Error finding AuthController', e);
      Get.put(AuthController());
      _authController = Get.find<AuthController>();
    }

    _loadResponderInfo();
    _listenToActiveEmergencies();
    _listenToActiveResponders();
    _listenToAssignments();
  }

  // Load responder information
  Future<void> _loadResponderInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = _authController.firebaseUser.value?.uid;

      if (userId != null) {
        responderId.value = userId;
        responderType.value = prefs.getString('responder_type') ?? 'unknown';
      }
    } catch (e) {
      LoggerUtil.error('Error loading responder info', e);
    }
  }

  // Listen to active emergencies
  void _listenToActiveEmergencies() {
    try {
      final stream = _databaseService.getActiveEmergencies();

      if (stream != null) {
        stream.listen((event) {
          if (event.snapshot.exists) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            final List<EmergencyModel> emergencies = [];

            data.forEach((key, value) {
              emergencies.add(EmergencyModel.fromRealtime(key, value));
            });

            // Sort emergencies by creation time (newest first)
            emergencies.sort((a, b) => DateTime.parse(b.createdAt)
                .compareTo(DateTime.parse(a.createdAt)));

            activeEmergencies.value = emergencies;
          } else {
            activeEmergencies.clear();
          }
        }, onError: (error) {
          LoggerUtil.error('Error listening to active emergencies', error);
        });
      }
    } catch (e) {
      LoggerUtil.error('Error setting up emergency listener', e);
    }
  }

  // Listen to active responders
  void _listenToActiveResponders() {
    try {
      final stream = _databaseService.getActiveResponders();

      if (stream != null) {
        stream.listen((event) {
          if (event.snapshot.exists) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            final List<ResponderModel> responders = [];

            data.forEach((key, value) {
              responders.add(ResponderModel.fromActiveResponder(key, value));
            });

            activeResponders.value = responders;
          } else {
            activeResponders.clear();
          }
        }, onError: (error) {
          LoggerUtil.error('Error listening to active responders', error);
        });
      }
    } catch (e) {
      LoggerUtil.error('Error setting up responder listener', e);
    }
  }

  // Listen to assignments
  void _listenToAssignments() {
    try {
      if (responderId.value.isEmpty) return;

      final stream = _databaseService.getAssignedEmergencies(responderId.value);

      if (stream != null) {
        stream.listen((event) {
          if (event.snapshot.exists) {
            final data = event.snapshot.value as Map<dynamic, dynamic>;
            final Map<String, String> assignments = {};

            data.forEach((key, value) {
              if (value is Map) {
                final emergencyId = value['emergencyId']?.toString() ?? '';
                if (emergencyId.isNotEmpty) {
                  assignments[key] = emergencyId;
                }
              }
            });

            assignedEmergencies.value = assignments;
          } else {
            assignedEmergencies.clear();
          }
        }, onError: (error) {
          LoggerUtil.error('Error listening to assignments', error);
        });
      }
    } catch (e) {
      LoggerUtil.error('Error setting up assignment listener', e);
    }
  }

  // Get nearby emergencies based on responder type
  List<EmergencyModel> getNearbyEmergencies() {
    if (currentPosition.value == null) return [];

    // Filter emergencies by type and distance
    return activeEmergencies.where((emergency) {
      // Check if emergency type matches responder type
      bool typeMatch =
          _isEmergencyTypeMatch(emergency.emergencyType, responderType.value);

      // Calculate distance
      double distance = Geolocator.distanceBetween(
          currentPosition.value!.latitude,
          currentPosition.value!.longitude,
          emergency.latitude,
          emergency.longitude);

      // Return emergencies within 10km and matching type
      return typeMatch && distance <= 10000;
    }).toList();
  }

  // Check if emergency type matches responder type
  bool _isEmergencyTypeMatch(String emergencyType, String responderType) {
    switch (responderType.toLowerCase()) {
      case 'ambulance':
        return emergencyType.toLowerCase().contains('medical');
      case 'police':
        return emergencyType.toLowerCase().contains('police') ||
            emergencyType.toLowerCase().contains('crime');
      case 'firefighter':
        return emergencyType.toLowerCase().contains('fire') ||
            emergencyType.toLowerCase().contains('gas');
      default:
        return true; // Default to showing all emergencies
    }
  }

  // Assign responder to emergency
  Future<bool> assignToEmergency(String emergencyId) async {
    try {
      isAssigning.value = true;

      // Validate inputs
      if (responderId.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Responder ID not available',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isAssigning.value = false;
        return false;
      }

      if (currentPosition.value == null) {
        Get.snackbar(
          'Error',
          'Current location not available',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isAssigning.value = false;
        return false;
      }

      // Get emergency details
      final emergency = activeEmergencies.firstWhere(
        (e) => e.id == emergencyId,
        orElse: () => EmergencyModel(
          userId: '',
          userPhone: '',
          emergencyType: '',
          address: '',
          latitude: 0,
          longitude: 0,
          status: 'unknown',
          createdAt: DateTime.now().toString(),
        ),
      );

      if (emergency.userId.isEmpty) {
        Get.snackbar(
          'Error',
          'Emergency not found',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isAssigning.value = false;
        return false;
      }

      // Create assignment data
      final assignmentData = {
        'emergencyId': emergencyId,
        'userId': emergency.userId,
        'userLat': emergency.latitude.toString(),
        'userLong': emergency.longitude.toString(),
        'responderLat': currentPosition.value!.latitude.toString(),
        'responderLong': currentPosition.value!.longitude.toString(),
        'responderType': responderType.value,
        'responderID': responderId.value,
        'status': 'assigned',
        'assignedAt': DateTime.now().toString(),
      };

      // Assign responder to emergency
      bool success = await _databaseService.assignResponder(
          responderId.value, emergencyId, assignmentData);

      if (success) {
        Get.snackbar(
          'Success',
          'You have been assigned to this emergency',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        isAssigning.value = false;
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to assign to emergency',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isAssigning.value = false;
        return false;
      }
    } catch (e) {
      LoggerUtil.error('Error assigning to emergency', e);
      Get.snackbar(
        'Error',
        'An unexpected error occurred',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isAssigning.value = false;
      return false;
    }
  }

  // Update responder status
  Future<bool> updateResponderStatus(bool isActive) async {
    try {
      isLoading.value = true;

      if (responderId.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Responder ID not available',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoading.value = false;
        return false;
      }

      // Get current position if active
      if (isActive) {
        currentPosition.value = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ));
      }

      // Create location data
      Map<String, dynamic>? locationData;
      if (isActive && currentPosition.value != null) {
        locationData = {
          'lat': currentPosition.value!.latitude.toString(),
          'long': currentPosition.value!.longitude.toString(),
          'responderType': responderType.value,
          'responderID': responderId.value,
          'timestamp': DateTime.now().toString(),
        };
      }

      // Update responder status
      bool success = await _databaseService.updateResponderStatus(
          responderId.value, isActive, locationData);

      isLoading.value = false;
      return success;
    } catch (e) {
      LoggerUtil.error('Error updating responder status', e);
      isLoading.value = false;
      return false;
    }
  }
}
