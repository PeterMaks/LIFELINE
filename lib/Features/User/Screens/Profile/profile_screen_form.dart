import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Common Widgets/constants.dart';
import '../../../Emergency Contacts/add_contacts.dart';
import '../../../../Features/LandingPage/landing_page.dart';
import '../../../../Features/Responder/responder_dashboard.dart';
import '../../../../Features/Auth/Controllers/auth_controller.dart';
import 'extended_profile_screen.dart';

class ProfileFormWidget extends StatefulWidget {
  const ProfileFormWidget({super.key});

  @override
  State<ProfileFormWidget> createState() => _ProfileFormWidgetState();
}

class _ProfileFormWidgetState extends State<ProfileFormWidget> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  String userEmail = '';
  String userRole = 'civilian'; // Default role
  final authController = Get.put(AuthController());

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('user_name') ?? '';
      phoneController.text = prefs.getString('user_phone') ?? '';
      userEmail = prefs.getString('user_email') ?? 'user@example.com';
      userRole = prefs.getString('user_role') ?? 'civilian';
    });
  }

  Future<void> _saveProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', nameController.text);
    await prefs.setString('user_phone', phoneController.text);
  }

  Future<void> _switchUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);

    // Show confirmation
    Get.snackbar("Role Changed",
        "Your role has been changed to ${role == 'responder' ? 'Emergency Responder' : 'Civilian'}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2));

    // Navigate to appropriate dashboard
    if (role == 'responder') {
      Get.offAll(() => const ResponderDashboard());
    } else {
      Get.offAll(() => const LandingPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "User Info",
            style: TextStyle(
              color: Color(color),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: nameController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              if (value.trim().length < 2) {
                return 'Name must be valid';
              }
              return null;
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person_outline_rounded),
              labelText: "Full Name",
              hintText: "Full Name",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: phoneController,
            validator: (value) {
              bool isPhoneValid =
                  RegExp(r'^(?:[+0][1-9])?[0-9]{8,15}$').hasMatch(value!);
              if (!isPhoneValid) {
                return 'Invalid phone number';
              }
              return null;
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.phone),
              labelText: "Phone Number",
              hintText: "Phone Number",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(color),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _saveProfileData();
                  Get.snackbar("Save", "Profile Updated",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2));
                }
              },
              child: Text("Update".toUpperCase()),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(color),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              onPressed: () {
                Get.to(() => const AddContact(),
                    transition: Transition.rightToLeft,
                    duration: const Duration(seconds: 1),
                    arguments: userEmail);
              },
              child: Text("Emergency Contacts".toUpperCase()),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(color),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              onPressed: () {
                Get.to(() => const ExtendedProfileScreen(),
                    transition: Transition.rightToLeft,
                    duration: const Duration(seconds: 1));
              },
              child: Text("Extended Profile".toUpperCase()),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "App Settings",
            style: TextStyle(
              color: Color(color),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              title: const Text("User Role"),
              subtitle: Text(
                  userRole == 'responder' ? 'Emergency Responder' : 'Civilian'),
              trailing: Switch(
                value: userRole == 'responder',
                activeColor: Color(color),
                onChanged: (value) {
                  _switchUserRole(value ? 'responder' : 'civilian');
                },
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                // Show confirmation dialog
                Get.defaultDialog(
                  title: 'Sign Out',
                  middleText: 'Are you sure you want to sign out?',
                  textConfirm: 'Yes',
                  textCancel: 'No',
                  confirmTextColor: Colors.white,
                  cancelTextColor: Color(color),
                  buttonColor: Color(color),
                  onConfirm: () {
                    authController.signOut();
                  },
                );
              },
              child: Text("SIGN OUT".toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}
