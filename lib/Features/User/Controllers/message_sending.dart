import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Features/Emergency Contacts/emergency_contacts_controller.dart';
import 'emergency_details_controller.dart';

class MessageController extends GetxController {
  static MessageController get instance => Get.find();
  final emergencyContactsController = Get.put(EmergencyContactsController());
  static Position? _currentPosition;
  void _sendSMS(String message, List<String> recipients) async {
    if (recipients.isEmpty || recipients.every((phone) => phone.isEmpty)) {
      Get.snackbar(
        "Error",
        "No emergency contacts found. Please add emergency contacts.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    bool anySuccess = false;

    for (var i = 0; i < recipients.length; i++) {
      String phone = recipients[i].toString().trim();
      if (phone.isEmpty) continue;

      try {
        // Encode the message for URL
        final encodedMessage = Uri.encodeComponent(message);
        // Create SMS URI
        final Uri smsUri = Uri.parse('sms:$phone?body=$encodedMessage');

        // Launch SMS app
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          anySuccess = true;
          // Break after first successful launch to avoid opening multiple SMS apps
          break;
        }
      } catch (e) {
        debugPrint("Error sending SMS to $phone: $e");
      }
    }

    if (anySuccess) {
      Get.snackbar(
        "SMS",
        "Emergency SMS prepared. Please send the message.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        "SMS Error",
        "Could not open SMS app. Please send emergency message manually.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    debugPrint("Sending SMS to: $recipients");
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar("Disabled",
          'Location services are disabled. Please enable the services');
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar("Rejected", 'Location Permissions are denied.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Get.snackbar("Rejected",
          'Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }
    return true;
  }

  handleSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isGranted) {
      debugPrint("SMS Permission Granted");
      return true;
    } else {
      debugPrint("SMS Permission Denied");
      return false;
    }
  }

  Future<Position> getCurrentPosition() async {
    try {
      final hasPermission = await handleLocationPermission();

      if (!hasPermission) {
        return _createDefaultPosition();
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Get address from coordinates
      await _getAddressFromLatLng(_currentPosition!);

      return _currentPosition!;
    } catch (e) {
      debugPrint("Error getting current position: $e");
      return _createDefaultPosition();
    }
  }

  Position _createDefaultPosition() {
    return Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0);
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      String address =
          '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      debugPrint("Current address: $address");
    }).catchError((e) {
      debugPrint(e.toString());
    });
  }

  Future<void> sendLocationViaSMS(String emergencyType) async {
    try {
      // Get current position first
      Position position = await getCurrentPosition();

      // Check if position is valid (not default position)
      bool hasValidLocation = position.latitude != 0 || position.longitude != 0;

      // Try to find EmergencyDetailsController if it exists
      EmergencyDetailsController? emergencyDetailsController;
      try {
        emergencyDetailsController = Get.find<EmergencyDetailsController>();
      } catch (_) {
        // Controller not found, will use default message format
      }

      // Build the message
      String locationText = hasValidLocation
          ? "Location: http://www.google.com/maps/place/${position.latitude},${position.longitude}"
          : "Location: Unable to determine current location";

      String message;
      if (emergencyDetailsController != null) {
        // Enhanced message with emergency details
        String emergencyDetails =
            emergencyDetailsController.generateEmergencyMessage();
        message = "URGENT: $emergencyType\n\n"
            "$emergencyDetails\n\n"
            "$locationText\n\n"
            "Please respond immediately!";
      } else {
        // Default message format
        message = "URGENT: $emergencyType\n"
            "$locationText";
      }

      // Load emergency contacts and send SMS
      List<String> emergencyContacts =
          await emergencyContactsController.loadData();
      _sendSMS(message, emergencyContacts);
    } catch (e) {
      debugPrint("Error sending emergency SMS: $e");
      Get.snackbar(
        "Error",
        "Failed to send emergency message: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Get.snackbar("Location", "Location not found");
}
