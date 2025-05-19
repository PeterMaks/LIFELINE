import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:public_emergency_app/Features/Auth/Screens/login_confirmation_dialog.dart';
import 'package:public_emergency_app/Features/Auth/Screens/registration_confirmation_dialog.dart';
import 'package:public_emergency_app/Features/LandingPage/landing_page.dart';
import 'package:public_emergency_app/services/firebase_service.dart';
import 'package:public_emergency_app/utils/logger_util.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  // Firebase service
  late final FirebaseService _firebaseService;

  // Flag to track if Firebase service is available
  final isFirebaseServiceAvailable = false.obs;

  // Firebase auth instance
  final _auth = FirebaseAuth.instance;

  // Observable variables
  final isLoading = false.obs;
  final Rx<User?> firebaseUser = Rx<User?>(null);

  @override
  void onReady() {
    super.onReady();

    // Try to get the Firebase service
    try {
      _firebaseService = Get.find<FirebaseService>();
      isFirebaseServiceAvailable.value = true;
      LoggerUtil.info("Firebase service found in AuthController");
    } catch (e) {
      LoggerUtil.error("Firebase service not available in AuthController", e);
      isFirebaseServiceAvailable.value = false;
    }

    // Initialize auth state
    firebaseUser.value = _auth.currentUser;
    _auth.authStateChanges().listen(_setInitialScreen);

    LoggerUtil.info("AuthController initialized");
  }

  // Set initial screen based on auth state
  _setInitialScreen(User? user) async {
    firebaseUser.value = user;
  }

  // Register new user
  Future<bool> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String userType,
  }) async {
    try {
      isLoading.value = true;

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user ID
      final uid = userCredential.user!.uid;

      // Save user data to Realtime Database with extended information
      if (isFirebaseServiceAvailable.value) {
        await _firebaseService.usersRef.child(uid).set({
          'UserName': name,
          'email': email,
          'Phone': phone,
          'UserType': userType,
          'createdAt': DateTime.now().toString(),
          'updatedAt': DateTime.now().toString(),
          'profileComplete': false,
          'emergencyContacts': [],
          'medicalInfo': {
            'bloodType': '',
            'allergies': '',
            'medications': '',
            'medicalConditions': '',
            'emergencyNotes': '',
          },
          'settings': {
            'notificationsEnabled': true,
            'locationSharingEnabled': true,
            'darkModeEnabled': false,
          }
        });
      }

      // Save user role to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role',
          userType == 'emergency_responder' ? 'responder' : 'civilian');
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_email', email);

      // Show registration confirmation dialog
      Get.dialog(
        RegistrationConfirmationDialog(
          userType: userType,
          userName: name,
        ),
        barrierDismissible: false, // User must tap button to close dialog
      );

      return true;
    } on FirebaseAuthException catch (e) {
      String message = '';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already in use. Please use a different email.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use a stronger password.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }

      Get.snackbar(
        'Registration Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Login user
  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // Sign in with email and password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user data from database
      final uid = _auth.currentUser!.uid;

      // Only try to get data from Firebase if service is available
      Map<dynamic, dynamic>? userData;
      if (isFirebaseServiceAvailable.value) {
        final snapshot = await _firebaseService.usersRef.child(uid).get();
        if (snapshot.exists) {
          userData = snapshot.value as Map<dynamic, dynamic>;
        }
      }

      if (userData != null) {
        // Save user data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        final userType = userData['UserType'] as String;

        // Save basic user information
        await prefs.setString('user_role',
            userType == 'emergency_responder' ? 'responder' : 'civilian');
        await prefs.setString('user_name', userData['UserName'] as String);
        await prefs.setString('user_phone', userData['Phone'] as String);
        await prefs.setString('user_email', userData['email'] as String);
        await prefs.setString('user_id', uid);

        // Save login timestamp
        await prefs.setString('last_login', DateTime.now().toString());

        // Save login status
        await prefs.setBool('is_logged_in', true);

        // Save additional settings if available
        if (userData.containsKey('settings')) {
          final settings = userData['settings'] as Map<dynamic, dynamic>;
          if (settings.containsKey('notificationsEnabled')) {
            await prefs.setBool('notifications_enabled',
                settings['notificationsEnabled'] as bool);
          }
          if (settings.containsKey('locationSharingEnabled')) {
            await prefs.setBool('location_sharing_enabled',
                settings['locationSharingEnabled'] as bool);
          }
        }

        // Update last login timestamp if Firebase service is available
        if (isFirebaseServiceAvailable.value) {
          await _firebaseService.usersRef.child(uid).update({
            'lastLogin': DateTime.now().toString(),
          });
        }

        // Show login confirmation dialog
        Get.dialog(
          LoginConfirmationDialog(
            userType: userType,
            userName: userData['UserName'] as String,
          ),
          barrierDismissible: false, // User must tap button to close dialog
        );
      }

      return true;
    } on FirebaseAuthException catch (e) {
      String message = '';

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password. Please try again.';
          break;
        case 'invalid-credential':
          message =
              'Invalid credentials. Please check your email and password.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }

      Get.snackbar(
        'Login Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _auth.sendPasswordResetEmail(email: email);

      Get.snackbar(
        'Password Reset',
        'Password reset link sent to your email.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      String message = '';

      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        default:
          message = 'An error occurred. Please try again.';
      }

      Get.snackbar(
        'Password Reset Failed',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Clear user data from shared preferences
      final prefs = await SharedPreferences.getInstance();

      // Clear basic user information
      await prefs.setString('user_role', 'none');
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_email');
      await prefs.remove('user_id');

      // Clear login status
      await prefs.setBool('is_logged_in', false);

      // Clear additional settings
      await prefs.remove('notifications_enabled');
      await prefs.remove('location_sharing_enabled');

      // Show success message
      Get.snackbar(
        'Signed Out',
        'You have been successfully signed out',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navigate to landing page
      Get.offAll(() => const LandingPage());
    } catch (e) {
      Get.snackbar(
        'Error Signing Out',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
