import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/Responder/Screens/emergency_list_screen.dart';
import 'package:public_emergency_app/Features/User/Screens/Profile/profile_screen.dart';
import 'package:public_emergency_app/screens/geojson_map_screen.dart';
import 'package:public_emergency_app/utils/logger_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_switch/sliding_switch.dart';
import 'package:url_launcher/url_launcher.dart';
import '../User/Controllers/message_sending.dart';
import '../User/Screens/LiveStreaming/live_stream.dart';

class ResponderDashboard extends StatefulWidget {
  const ResponderDashboard({super.key});

  @override
  State<ResponderDashboard> createState() => _ResponderDashboardState();
}

// Get user ID from Firebase Auth
Future<String> getUserId() async {
  try {
    // Try to get from Firebase Auth first
    final firebaseAuth = FirebaseAuth.instance;
    final currentUser = firebaseAuth.currentUser;

    if (currentUser != null && currentUser.uid.isNotEmpty) {
      return currentUser.uid;
    }

    // Fallback to device ID if Firebase Auth is not available
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ??
          DateTime.now().millisecondsSinceEpoch.toString();
    }
    return DateTime.now().millisecondsSinceEpoch.toString();
  } catch (e) {
    debugPrint("Error getting user ID: $e");
    // Fallback to timestamp if everything fails
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// Helper function for distance calculation
double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

class _ResponderDashboardState extends State<ResponderDashboard> {
  // Database references
  late DatabaseReference assignmedRef;
  late DatabaseReference activeRespondersRef;
  late DatabaseReference userRef;

  // State variables
  String userType = '';
  final messageController = Get.put(MessageController());
  late Position position;
  String status = '';
  bool _switchValue = false;
  late String deviceId;

  // Flag to track initialization
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeResponder();
    _loadSwitchValue();
  }

  Future<void> _initializeResponder() async {
    try {
      // Get user ID from Firebase Auth
      deviceId = await getUserId();

      // Log the user ID for debugging
      debugPrint("Responder ID: $deviceId");

      // Initialize database references
      assignmedRef =
          FirebaseDatabase.instance.ref().child('assigned/$deviceId');
      activeRespondersRef =
          FirebaseDatabase.instance.ref().child('activeResponders');
      userRef = FirebaseDatabase.instance.ref().child('Users');

      // Load responder type from user data
      try {
        final userSnapshot = await userRef.child(deviceId).get();
        if (userSnapshot.exists) {
          final userData = userSnapshot.value as Map<dynamic, dynamic>;
          userType = userData['UserType'] ?? 'emergency_responder';
          debugPrint("Loaded responder type: $userType");
        } else {
          userType = 'emergency_responder';
          debugPrint("User data not found, using default responder type");
        }
      } catch (e) {
        userType = 'emergency_responder';
        debugPrint("Error loading user data: $e");
      }

      // Mark as initialized and update UI
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint("Error initializing responder: $e");
      // Show error to user
      Get.snackbar(
        "Initialization Error",
        "Failed to initialize responder dashboard. Please restart the app.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _loadSwitchValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _switchValue = prefs.getBool('switchValue') ?? false;
    });
  }

  Future<void> _saveSwitchValue(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('switchValue', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(color),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(
            side: BorderSide(color: Colors.white24, width: 4)),
        onPressed: () {
          Get.to(() => const ProfileScreen());
        },
        child: const Icon(Icons.person),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Color(color),
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(Get.height * 0.16),
          child: Container(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                        image: const AssetImage(
                            "assets/logos/emergencyAppLogo.png"),
                        height: Get.height * 0.07),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Responder Dashboard",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SlidingSwitch(
                        value: _switchValue,
                        width: 100.0,
                        onChanged: (value) {
                          setState(() {
                            _saveSwitchValue(value);
                            _switchValue = value;
                            status = getStatus();
                          });
                          _saveSwitchValue(value);
                        },
                        height: 40.0,
                        textOff: 'OFF',
                        textOn: 'ON',
                        colorOn: Colors.green,
                        colorOff: Colors.red,
                        onSwipe: () {
                          debugPrint(_switchValue.toString());
                        },
                        onTap: () {},
                        onDoubleTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Emergency List Button
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => EmergencyListScreen());
                    },
                    icon: const Icon(Icons.emergency),
                    label: const Text('View Nearby Emergencies'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Map Button
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.to(() => GeoJsonMapScreen());
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('View Emergency Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Current Assignment
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: assignmedRef.onValue,
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data!.snapshot.value != null) {
                        final data = snapshot.data!.snapshot.value
                            as Map<dynamic, dynamic>;

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          child: Card(
                            color: Color(color),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              onTap: () async {
                                var lat = data['userLat'];
                                var long = data['userLong'];

                                if (lat == null || long == null) {
                                  Get.snackbar(
                                      'Error', 'No Emergency Location Found');
                                  return;
                                }

                                final url = Platform.isAndroid
                                    ? 'https://www.google.com/maps/search/?api=1&query=$lat,$long'
                                    : 'comgooglemaps://?saddr=&daddr=$lat,$long&directionsmode=driving';

                                final urlAppleMaps =
                                    'https://maps.apple.com/?q=$lat,$long';

                                try {
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(Uri.parse(url));
                                  } else if (!Platform.isAndroid &&
                                      await canLaunchUrl(
                                          Uri.parse(urlAppleMaps))) {
                                    await launchUrl(Uri.parse(urlAppleMaps));
                                  } else {
                                    throw 'Could not launch map';
                                  }
                                } catch (e) {
                                  Get.snackbar(
                                      'Error', 'Could not open map: $e');
                                }
                              },
                              title: Text(
                                data['userAddress'] ??
                                    'No Emergency Request Yet',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                              subtitle: Text(
                                _buildDistanceText(data),
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.video_call,
                                    color: Colors.red, size: 30),
                                onPressed: () {
                                  if (data['userLat'] == null ||
                                      data['userLong'] == null) {
                                    Get.snackbar(
                                        'Error', 'No Emergency Request Yet');
                                    return;
                                  }

                                  Get.to(() => LiveStreamingPage(
                                        liveId: data['userID'],
                                        isHost: false,
                                      ));
                                },
                              ),
                            ),
                          ),
                        );
                      }

                      return const Center(
                        child: Text(
                          'No active assignments',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  String _buildDistanceText(Map<dynamic, dynamic> data) {
    if (data['userLat'] != null &&
        data['userLong'] != null &&
        data['responderLat'] != null &&
        data['responderLong'] != null) {
      final distance = calculateDistance(
          double.tryParse(data['userLat'].toString()) ?? 0.0,
          double.tryParse(data['userLong'].toString()) ?? 0.0,
          double.tryParse(data['responderLat'].toString()) ?? 0.0,
          double.tryParse(data['responderLong'].toString()) ?? 0.0);

      return 'Distance: ${distance.toStringAsFixed(2)} km';
    }

    return 'No location data available';
  }

  String getStatus() {
    if (_switchValue == true) {
      setState(() {
        status = 'Available';
        setResponderData();
      });
    } else {
      setState(() {
        status = 'Unavailable';
        activeRespondersRef.child(deviceId).remove();
      });
    }
    return status;
  }

  Color setColor() {
    if (_switchValue == true) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  Future<void> setResponderData() async {
    try {
      // Get location permission
      await messageController.handleLocationPermission();

      // Get current position
      Position position = await messageController.getCurrentPosition();

      // Only update if we have a valid position
      if (position.latitude != 0 || position.longitude != 0) {
        // Create responder data with more details
        final responderData = {
          "lat": position.latitude.toString(),
          "long": position.longitude.toString(),
          "latitude":
              position.latitude, // Include both formats for compatibility
          "longitude": position.longitude,
          "responderType": userType,
          "responderID": deviceId,
          "timestamp": DateTime.now().toString(),
          "status": "available",
        };

        // Update in Firebase
        await activeRespondersRef.child(deviceId).set(responderData);

        // Also update user location in Users node
        await userRef.child(deviceId).update({
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toString(),
          }
        });

        debugPrint("Responder data updated successfully");
      } else {
        debugPrint("Could not get valid location for responder");
        Get.snackbar(
          "Location Error",
          "Could not determine your location. Please check your location settings.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Error setting responder data: $e");
      Get.snackbar(
        "Error",
        "Failed to update responder status: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<String> getUserType() async {
    try {
      // Try to get from Firebase first
      final userSnapshot = await userRef.child(deviceId).get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        return userData['UserType'] ?? 'emergency_responder';
      }

      // If not in Firebase, try to get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString('responder_type');
      if (savedType != null && savedType.isNotEmpty) {
        return savedType;
      }

      // Default fallback
      return 'emergency_responder';
    } catch (e) {
      debugPrint("Error getting user type: $e");
      return 'emergency_responder';
    }
  }
}
