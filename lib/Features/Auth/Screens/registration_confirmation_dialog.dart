import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/Responder/responder_dashboard.dart';
import 'package:public_emergency_app/Features/User/Screens/bottom_nav.dart';

class RegistrationConfirmationDialog extends StatelessWidget {
  final String userType;
  final String userName;

  const RegistrationConfirmationDialog({
    Key? key,
    required this.userType,
    required this.userName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isResponder = userType == 'emergency_responder' || userType == 'responder';
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context, isResponder),
    );
  }

  Widget contentBox(BuildContext context, bool isResponder) {
    return Stack(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(
            left: 20,
            top: 65,
            right: 20,
            bottom: 20,
          ),
          margin: const EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Registration Successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(color),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Welcome, $userName!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                isResponder
                    ? 'You have been registered as an Emergency Responder. You can now respond to emergency calls and help those in need.'
                    : 'You have been registered as a Civilian. You can now use the app to request emergency assistance when needed.',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(color),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Get.back(); // Close the dialog
                      
                      // Navigate to the appropriate screen based on user type
                      if (isResponder) {
                        Get.offAll(() => const ResponderDashboard());
                      } else {
                        Get.offAll(() => const NavBar());
                      }
                    },
                    child: Text(
                      isResponder ? 'Go to Responder Dashboard' : 'Go to Dashboard',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          child: CircleAvatar(
            backgroundColor: Color(color),
            radius: 45,
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ],
    );
  }
}
