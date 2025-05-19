import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/User/Screens/Profile/profile_screen_form.dart';
import 'package:public_emergency_app/Features/User/Screens/User%20Dashboard/user_dashboard.dart';
import '../../../../Common Widgets/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context){

    return Scaffold(
      floatingActionButton:FloatingActionButton(
        backgroundColor: Color(color),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(
            side: BorderSide(
                color: Colors.white24, width: 4)),
        onPressed: () {
          Get.offAll(() => const UserDashboard());
        },
        child: const Icon(Icons.home),
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
            preferredSize:  Size.fromHeight(Get.height * 0.1),
            child: Container(
              padding: const EdgeInsets.only(bottom: 15),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Image(image: const AssetImage("assets/logos/emergencyAppLogo.png"), height: Get.height * 0.08),
                    ],
                  ),

                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:  [
                        Text(
                          "Profile",
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
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(30),
          child: const Column(
            children: [
              ProfileFormWidget(),
            ],
          ),
        ),
      ),
    );
  }
}



