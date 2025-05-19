import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/Auth/Controllers/auth_controller.dart';
import 'package:public_emergency_app/Features/User/Controllers/emergency_details_controller.dart';
import 'package:public_emergency_app/Features/User/Controllers/message_sending.dart';
import 'package:public_emergency_app/models/emergency_model.dart';
import 'package:public_emergency_app/services/database_service.dart';
import 'package:public_emergency_app/utils/logger_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyCreationController extends GetxController {
  static EmergencyCreationController get instance => Get.find();

  // Dependencies
  late final DatabaseService _databaseService;
  late final MessageController _messageController;
  late final AuthController _authController;

  // Observable variables
  final RxBool isCreatingEmergency = false.obs;
  final RxBool isLocationLoading = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxString currentAddress = ''.obs;
  final RxString emergencyId = ''.obs;
  final RxString emergencyStatus = 'pending'.obs;

  // Form fields
  final Rx<String> emergencyType = ''.obs;
  final Rx<String> emergencyDescription = ''.obs;
  final RxBool sendSmsToContacts = true.obs;
  final RxBool startLiveStream = false.obs;

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
      _messageController = Get.find<MessageController>();
    } catch (e) {
      LoggerUtil.error('Error finding MessageController', e);
      Get.put(MessageController());
      _messageController = Get.find<MessageController>();
    }

    try {
      _authController = Get.find<AuthController>();
    } catch (e) {
      LoggerUtil.error('Error finding AuthController', e);
      Get.put(AuthController());
      _authController = Get.find<AuthController>();
    }

    // Request location permission when controller is initialized
    _messageController.handleLocationPermission();
  }

  // Get current location
  Future<bool> getCurrentLocation() async {
    try {
      isLocationLoading.value = true;

      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permission is required for emergency services',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          isLocationLoading.value = false;
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Denied',
          'Location permission is permanently denied. Please enable it in settings.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        isLocationLoading.value = false;
        return false;
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Service Disabled',
          'Please enable location services for emergency assistance',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLocationLoading.value = false;
        return false;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).catchError((error) {
        LoggerUtil.error('Error getting position with high accuracy', error);
        // Fall back to lower accuracy if high accuracy times out
        return Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
      });

      currentPosition.value = position;

      // Get address from coordinates
      if (position.latitude != 0 || position.longitude != 0) {
        await _getAddressFromLatLng(position);
        isLocationLoading.value = false;
        return true;
      } else {
        currentAddress.value = 'Unable to determine location';
        isLocationLoading.value = false;
        return false;
      }
    } catch (e) {
      LoggerUtil.error('Error getting current location', e);
      currentAddress.value = 'Error getting location';
      isLocationLoading.value = false;

      // Show a more helpful error message
      Get.snackbar(
        'Location Error',
        'Could not get your location. Please check your settings and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    }
  }

  // Get address from coordinates
  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentAddress.value = '${place.street}, ${place.subLocality}, '
            '${place.locality}, ${place.administrativeArea}, '
            '${place.postalCode}, ${place.country}';
      } else {
        currentAddress.value = 'Address not found';
      }
    } catch (e) {
      LoggerUtil.error('Error getting address from coordinates', e);
      currentAddress.value = 'Error getting address';
    }
  }

  // Create emergency
  Future<bool> createEmergency() async {
    try {
      isCreatingEmergency.value = true;

      // Validate required fields
      if (emergencyType.value.isEmpty) {
        Get.snackbar(
          'Error',
          'Please select an emergency type',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isCreatingEmergency.value = false;
        return false;
      }

      // Get current location if not already available
      if (currentPosition.value == null) {
        bool locationSuccess = await getCurrentLocation();
        if (!locationSuccess) {
          Get.snackbar(
            'Location Error',
            'Unable to get your current location. Please check your location settings.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          isCreatingEmergency.value = false;
          return false;
        }
      }

      // Get user information
      final prefs = await SharedPreferences.getInstance();
      final userId = _authController.firebaseUser.value?.uid ?? '';
      final userPhone = prefs.getString('user_phone') ?? '';
      final userName = prefs.getString('user_name') ?? '';

      if (userId.isEmpty) {
        Get.snackbar(
          'Error',
          'User not authenticated. Please log in again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isCreatingEmergency.value = false;
        return false;
      }

      // Get emergency details if available
      EmergencyDetailsController? detailsController;
      Map<String, dynamic> additionalInfo = {};

      try {
        detailsController = Get.find<EmergencyDetailsController>();
        additionalInfo = {
          'condition': detailsController.selectedCondition,
          'symptoms': detailsController.symptoms,
          'additionalInfo': detailsController.additionalInfo,
          'isConscious': detailsController.isConscious,
          'isBreathing': detailsController.isBreathing,
          'isBleeding': detailsController.isBleeding,
        };
      } catch (e) {
        // Details controller not found, continue without it
      }

      // Create emergency model
      final emergency = EmergencyModel(
        userId: userId,
        userPhone: userPhone,
        emergencyType: emergencyType.value,
        address: currentAddress.value,
        latitude: currentPosition.value!.latitude,
        longitude: currentPosition.value!.longitude,
        status: 'active',
        createdAt: DateTime.now().toString(),
        additionalInfo: {
          'userName': userName,
          'description': emergencyDescription.value,
          ...additionalInfo,
        },
      );

      // Save emergency to database
      final emergencyIdResult =
          await _databaseService.createEmergency(emergency.toMap());

      if (emergencyIdResult != null) {
        emergencyId.value = emergencyIdResult;
        emergencyStatus.value = 'active';

        // Send SMS to emergency contacts if enabled
        if (sendSmsToContacts.value) {
          await _messageController.sendLocationViaSMS(emergencyType.value);
        }

        isCreatingEmergency.value = false;
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to create emergency. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isCreatingEmergency.value = false;
        return false;
      }
    } catch (e) {
      LoggerUtil.error('Error creating emergency', e);
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isCreatingEmergency.value = false;
      return false;
    }
  }

  // Cancel emergency
  Future<bool> cancelEmergency() async {
    try {
      if (emergencyId.value.isEmpty) {
        return true; // No emergency to cancel
      }

      bool success = await _databaseService.updateEmergencyStatus(
          emergencyId.value, 'cancelled');

      if (success) {
        emergencyStatus.value = 'cancelled';
        return true;
      } else {
        Get.snackbar(
          'Error',
          'Failed to cancel emergency. Please try again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      LoggerUtil.error('Error cancelling emergency', e);
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Reset controller
  void reset() {
    emergencyType.value = '';
    emergencyDescription.value = '';
    sendSmsToContacts.value = true;
    startLiveStream.value = false;
    emergencyId.value = '';
    emergencyStatus.value = 'pending';
  }
}
