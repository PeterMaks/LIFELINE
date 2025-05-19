import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../Common Widgets/constants.dart';
import '../../Controllers/message_sending.dart';
import '../EmergencyCreation/emergency_creation_screen.dart';

class FirefighterOptions extends StatefulWidget {
  const FirefighterOptions({Key? key}) : super(key: key);

  @override
  State<FirefighterOptions> createState() => _FirefighterOptionsState();
}

class _FirefighterOptionsState extends State<FirefighterOptions> {
  final smsController = Get.put(MessageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            preferredSize: Size.fromHeight(Get.height * 0.1),
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
                          "Fire Department Options",
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOptionCard(
              icon: Icons.map,
              iconColor: Colors.orange,
              title: 'Fire Station Map',
              subtitle: 'Find the nearest fire station on the map',
              onTap: () => _openMap(context),
            ),
            _buildOptionCard(
              icon: Icons.call,
              iconColor: Colors.orange,
              title: 'Call Fire Department',
              subtitle: 'Directly call the fire emergency helpline',
              onTap: () => _makeEmergencyCall(),
            ),
            _buildOptionCard(
              icon: Icons.local_fire_department,
              iconColor: Colors.white,
              title: 'Report Fire',
              subtitle: 'Report a fire or gas leak emergency',
              color: const Color(0xffff4500),
              onTap: () => _showEmergencyDetails(context, "Fire Emergency"),
            ),
            _buildOptionCard(
              icon: Icons.message,
              iconColor: Colors.white,
              title: 'Send Emergency Alert',
              subtitle: 'Send a detailed emergency alert to contacts',
              color: const Color(0xfff85757),
              onTap: () => _showEmergencyDetails(context, "Fire/Gas Emergency"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15.0)),
        ),
        tileColor: color ?? Colors.white,
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _openMap(BuildContext context) async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    var lat = position.latitude;
    var long = position.longitude;

    String url = '';
    String urlAppleMaps = '';

    if (Platform.isAndroid) {
      url = "https://www.google.com/maps/search/fire+station/@$lat,$long,12.5z";
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        throw 'Could not launch $url';
      }
    } else {
      urlAppleMaps = 'https://maps.apple.com/?q=fire+station&sll=$lat,$long';
      url = 'comgooglemaps://?q=fire+station&center=$lat,$long';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else if (await canLaunchUrl(Uri.parse(urlAppleMaps))) {
        await launchUrl(Uri.parse(urlAppleMaps));
      } else {
        throw 'Could not launch $url';
      }
    }
  }

  Future<void> _makeEmergencyCall() async {
    if (await Permission.phone.request().isGranted) {
      var url = Uri.parse("tel:16");
      await launchUrl(url);
    } else {
      Get.snackbar(
        "Permission Denied",
        "Please enable phone permission to make emergency calls",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showEmergencyDetails(BuildContext context, String type) {
    Get.to(() => EmergencyCreationScreen(initialEmergencyType: type));
  }
}
