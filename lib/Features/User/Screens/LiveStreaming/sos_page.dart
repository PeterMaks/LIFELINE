import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../../Common Widgets/constants.dart';
import '../../Controllers/message_sending.dart';
import 'live_stream.dart';

class LiveStreamUser extends StatefulWidget {
  const LiveStreamUser({Key? key}) : super(key: key);

  @override
  State<LiveStreamUser> createState() => _LiveStreamUserState();
}

final idController = TextEditingController();
final smsController = Get.put(MessageController());

class _LiveStreamUserState extends State<LiveStreamUser> {
  // Generate a unique ID for the user session
  final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();

  @override
  void initState() {
    super.initState();
    smsController.handleLocationPermission();

    // smsController.sendLocationViaSMS("SOS BUTTON PRESSED");
  }

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
                          "SOS",
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: Get.width * 0.8,
                height: Get.height * 0.2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 15,
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () async {
                    smsController.sendLocationViaSMS("SOS BUTTON PRESSED");
                    saveCurrentLocation().whenComplete(() {
                      jumpToLiveStream(uniqueId, true);
                    });
                  },
                  child: const Text("SOS", style: TextStyle(fontSize: 40)),
                ),
              ),
              SizedBox(
                height: Get.height * 0.05,
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Press the button to send your location to the rescue headquarters and send distress sms to your emergency contacts",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  saveCurrentLocation() async {
    final ref = FirebaseDatabase.instance.ref("sos/$uniqueId");
    await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).then((position) async {
      await placemarkFromCoordinates(position.latitude, position.longitude)
          .then((List<Placemark> placemarks) {
        Placemark place = placemarks[0];
        String address =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
        ref.set({
          "time":
              "${DateTime.now().hour}:${DateTime.now().minute} ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
          "address": address,
          "lat": position.latitude.toString(),
          "long": position.longitude.toString(),
          "videoId": uniqueId,
        });
      });
    });
  }

  jumpToLiveStream(String liveId, bool isHost) {
    if (liveId.isNotEmpty) {
      Get.to(
        () => LiveStreamingPage(
          liveId: liveId,
          isHost: isHost,
        ),
      );
    } else {
      Get.snackbar("Error", "Please enter a valid ID");
    }
  }
}
