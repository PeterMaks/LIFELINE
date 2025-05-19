import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/LandingPage/landing_page.dart';
import 'package:public_emergency_app/Features/Responder/responder_dashboard.dart';
import 'package:public_emergency_app/Features/User/Screens/bottom_nav.dart';
import 'package:public_emergency_app/Features/Auth/Controllers/auth_controller.dart';
import 'package:public_emergency_app/services/firebase_service.dart';
import 'package:public_emergency_app/services/database_service.dart';
import 'package:public_emergency_app/utils/logger_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:public_emergency_app/screens/geojson_map_screen.dart';
import 'firebase_options.dart';

void main() async {
  // Catch any errors during initialization
  try {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase directly first
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      LoggerUtil.info("Firebase core initialized successfully");
    } catch (e) {
      LoggerUtil.error("Error initializing Firebase core", e);
      // Continue without Firebase if it fails
    }

    // Create and register the Firebase Service
    try {
      // Create the service first
      final firebaseService = FirebaseService();

      // Register it with GetX before initialization
      Get.put<FirebaseService>(firebaseService, permanent: true);

      // Now initialize it
      await firebaseService.init();

      LoggerUtil.info("Firebase service initialized successfully");
    } catch (e) {
      LoggerUtil.error("Error initializing Firebase service", e);
      // Continue without Firebase service if it fails
    }

    // Initialize database service
    try {
      // Create and initialize the Database Service
      final databaseService = DatabaseService();
      await databaseService.init();

      // Register the initialized service with GetX
      Get.put<DatabaseService>(databaseService, permanent: true);

      LoggerUtil.info("Database service initialized successfully");
    } catch (e) {
      LoggerUtil.error("Error initializing Database service", e);
      // Continue without Database service if it fails
    }

    // Initialize auth controller with error handling
    try {
      Get.put(AuthController());
      LoggerUtil.info("Auth controller initialized");
    } catch (e) {
      LoggerUtil.error("Error initializing Auth controller", e);
      // Continue without auth controller if it fails
    }

    // Get user preferences with error handling
    String userRole = 'none';
    try {
      final prefs = await SharedPreferences.getInstance();
      userRole = prefs.getString('user_role') ?? 'none';
      LoggerUtil.info("User role loaded: $userRole");
    } catch (e) {
      LoggerUtil.error("Error loading user preferences", e);
      // Continue with default role if preferences fail
    }

    // Run the app
    runApp(MyApp(initialUserRole: userRole));
  } catch (e) {
    // Fallback to a minimal app if everything fails
    LoggerUtil.error("Critical error during initialization", e);
    runApp(const FallbackApp());
  }
}

// Fallback app in case of critical errors
class FallbackApp extends StatelessWidget {
  const FallbackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Response',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Emergency Response'),
        ),
        body: const Center(
          child: Text('Loading app...'),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final String initialUserRole;

  const MyApp({super.key, required this.initialUserRole});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Emergency Response App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    // Check if user is authenticated
    bool isLoggedIn = false;

    try {
      // Try to get the Firebase service
      final firebaseService = Get.find<FirebaseService>();
      isLoggedIn = firebaseService.isLoggedIn;
      LoggerUtil.info("Firebase service found in MyApp");
    } catch (e) {
      // If Firebase service is not available, check initialUserRole
      LoggerUtil.error("Firebase service not available in MyApp", e);
      isLoggedIn = initialUserRole != 'none';
    }

    if (isLoggedIn) {
      // User is logged in, check role
      switch (initialUserRole) {
        case 'responder':
          return const ResponderDashboard();
        case 'civilian':
          return const NavBar();
        default:
          return const LandingPage();
      }
    } else {
      // User is not logged in, show landing page
      return const LandingPage();
    }
  }
}
