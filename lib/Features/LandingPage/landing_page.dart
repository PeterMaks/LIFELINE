import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/User/Screens/bottom_nav.dart';
import 'package:public_emergency_app/Features/Responder/responder_dashboard.dart';
import 'package:public_emergency_app/Features/Auth/Screens/login_screen.dart';
import 'package:public_emergency_app/Features/Auth/Screens/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  // Method to save user role preference and navigate to appropriate screen
  Future<void> _selectRole(String role) async {
    // Save the selected role to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);

    // Navigate to the appropriate screen
    if (role == 'civilian') {
      Get.off(() => const NavBar());
    } else if (role == 'responder') {
      Get.off(() => const ResponderDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(color), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo
              Image.asset(
                'assets/logos/emergencyAppLogo.png',
                height: 120,
                width: 120,
              ),
              const SizedBox(height: 20),
              // App Title
              Text(
                'Emergency Response',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose your role',
                style: TextStyle(
                  fontSize: 18,
                  color:
                      Colors.white.withValues(alpha: 230), // 0.9 * 255 = ~230
                ),
              ),
              const Spacer(),
              // User Option
              _buildRoleButton(
                title: 'Civilian',
                subtitle: 'Request emergency assistance',
                icon: Icons.person,
                onTap: () => _selectRole('civilian'),
              ),
              const SizedBox(height: 20),
              // EMS Option
              _buildRoleButton(
                title: 'Emergency Responder',
                subtitle: 'Police, Ambulance, Fire Brigade',
                icon: Icons.emergency,
                onTap: () => _selectRole('responder'),
              ),
              const SizedBox(height: 40),
              // Login/Register Option
              _buildRoleButton(
                title: 'Login or Register',
                subtitle: 'Access your account',
                icon: Icons.login,
                onTap: () => Get.to(() => const LoginScreen()),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Color(color).withValues(alpha: 26), // 0.1 * 255 = ~26
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Color(color),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
