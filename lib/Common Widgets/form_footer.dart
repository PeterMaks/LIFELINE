import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Features/User/Screens/User Dashboard/user_dashboard.dart';

class FooterWidget extends StatelessWidget {
  final String text;
  const FooterWidget({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          TextButton(
            style: ButtonStyle(
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.transparent)))),
            onPressed: () {
              Get.offAll(() => const UserDashboard());
            },
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
