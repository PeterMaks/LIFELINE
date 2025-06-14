import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'dart:math';
import '../Response Screen/emergencies_screen.dart';

class SelectResponder extends StatefulWidget {
  final String userID;
  final double userLat;
  final double userLong;
  final String userAddress;
  final String? userPhone;

  const SelectResponder(
      {super.key,
      required this.userID,
      required this.userLat,
      required this.userLong,
      required this.userAddress,
      this.userPhone});

  @override
  State<SelectResponder> createState() => _SelectResponderState();
}

double calculateDistance(lat1, lon1, lat2, lon2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((lat2 - lat1) * p) / 2 +
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
  return 12742 * asin(sqrt(a));
}

class _SelectResponderState extends State<SelectResponder> {
  final ref = FirebaseDatabase.instance.ref().child('activeResponders');

  @override
  Widget build(BuildContext context) {
    // No need for initState here

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
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                ),
                Center(
                  child: SizedBox.fromSize(
                    size: const Size(36, 36),
                    child: ClipOval(
                      child: Material(
                        color: Color(color),
                        child: InkWell(
                          splashColor: Colors.white,
                          onTap: () {
                            Get.back();
                          },
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 30,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                        image: const AssetImage(
                            "assets/logos/emergencyAppLogo.png"),
                        height: Get.height * 0.08),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Select Responders",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: ref.onValue,
        builder: (BuildContext context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasData) {
            DataSnapshot dataSnapshot = snapshot.data!.snapshot;
            Map<dynamic, dynamic> map = dataSnapshot.value as dynamic ?? {};
            List<dynamic> list = [];
            list.clear();
            list = map.values.toList();

            return ListView.builder(
              itemCount: snapshot.data!.snapshot.children.length,
              itemBuilder: (context, index) {
                return Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: ListTile(
                      // onTap: () async{
                      //   var lat= list[index]['lat'];
                      //   var long= list[index]['long'];
                      //   String url = '';
                      //   String urlAppleMaps = '';
                      //   if (Platform.isAndroid) {
                      //     url = 'http://www.google.com/maps/place/$lat,$long';
                      //     if (await canLaunchUrl(Uri.parse(url))) {
                      //       await launchUrl(Uri.parse(url));
                      //     } else {
                      //       throw 'Could not launch $url';
                      //     }
                      //   } else {
                      //     urlAppleMaps = 'https://maps.apple.com/?q=$lat,$long';
                      //     url = 'comgooglemaps://?saddr=&daddr=$lat,$long&directionsmode=driving';
                      //     if (await canLaunchUrl(Uri.parse(url))) {
                      //       await launchUrl(Uri.parse(url));
                      //     } else if (await canLaunchUrl(Uri.parse(urlAppleMaps))) {
                      //       await launchUrl(Uri.parse(urlAppleMaps));
                      //     } else {
                      //       throw 'Could not launch $url';
                      //     }
                      //   }
                      // },
                      onTap: () {
                        // Variables are parsed but not used yet
                        // Will be used in future implementation for showing responder details
                        debugPrint(
                            "Selected responder at location: ${list[index]['lat']}, ${list[index]['long']}");
                      },
                      tileColor: Color(color),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: Text(
                        list[index]['responderType'],
                        // "Responder Type",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      subtitle: Text(
                        "Distance from this user : ${calculateDistance(widget.userLat, widget.userLong, double.parse(list[index]['lat']), double.parse(list[index]['long'])).toStringAsFixed(2)} km",
                        // list[index]['long'],
                        // "Distance from this user : 0 km",
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.assignment_turned_in_outlined,
                            color: Colors.red, size: 30),
                        onPressed: () {
                          //save the user data in active responders data storage
                          final usersRef =
                              FirebaseDatabase.instance.ref().child('assigned');
                          usersRef.child(list[index]['responderID']).set({
                            'responderLat': list[index]['lat'],
                            'responderLong': list[index]['long'],
                            'responderID': list[index]['responderID'],
                            'userID': widget.userID,
                            'userLat': widget.userLat,
                            'userLong': widget.userLong,
                            'userAddress': widget.userAddress,
                            'userPhone': widget.userPhone,
                          }).whenComplete(() {
                            FirebaseDatabase.instance
                                .ref()
                                .child('sos')
                                .child(widget.userID)
                                .remove();
                          });
                          Get.snackbar("Assigned",
                              'This Emergency has been assigned to the responder');
                          Get.off(() => const EmergenciesScreen());
                        },
                      )),
                );
              },
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
