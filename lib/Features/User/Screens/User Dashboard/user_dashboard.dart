import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/User/Controllers/message_sending.dart';
import 'package:public_emergency_app/Features/User/Screens/User DashBoard/grid_dash.dart';

import '../../../../Common Widgets/constants.dart';
// import 'login_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({Key? key}) : super(key: key);

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    MessageController().handleSmsPermission();
  }
  final _messageController = Get.put(MessageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('DashBoard'),
      // ),

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
            preferredSize:  Size.fromHeight(Get.height * 0.1),
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
                          height: Get.height * 0.08),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dashboard",
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )),
      ),

      body: Container(
        margin: EdgeInsets.only(top: Get.height * 0.1),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: GridDashboard(),
        ),
      ),
    );
  }
}
