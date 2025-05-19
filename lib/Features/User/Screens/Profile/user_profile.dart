import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Emergency Contacts/add_contacts.dart';
import '../../../Emergency Contacts/emergency_contacts.dart';
import '../../../../Common Widgets/constants.dart';
import '../User Dashboard/user_dashboard.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String userName = '';
  String userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'User';
      userPhone = prefs.getString('user_phone') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(color),
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor:
                  Color(color).withValues(alpha: 26), // 0.1 * 255 = ~26
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 40,
                  color: Color(color),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userPhone,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            _buildButton(
              "Add Emergency Contacts",
              Colors.green,
              () => Get.to(() => const AddContact()),
            ),
            const SizedBox(height: 20),
            _buildButton(
              "View Emergency Contacts",
              Colors.blue,
              () => Get.to(() => const ContactListScreen()),
            ),
            const SizedBox(height: 20),
            _buildButton(
              "Back to Dashboard",
              Color(color),
              () => Get.offAll(() => const UserDashboard()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        minimumSize: const Size(200, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.0),
        ),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
