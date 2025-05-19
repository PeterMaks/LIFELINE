import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Features/User/Controllers/message_sending.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String? _currentAddress;
  Position? _currentPosition;
  final _messageController = Get.put(MessageController());

  // This method is kept for future use but commented out to avoid unused code warnings
  // Future<bool> _handleLocationPermission() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;
  //
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           content: Text(
  //               'Location services are disabled. Please enable the services')));
  //     }
  //     return false;
  //   }
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Location permissions are denied')));
  //       }
  //       return false;
  //     }
  //   }
  //   if (permission == LocationPermission.deniedForever) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           content: Text(
  //               'Location permissions are permanently denied, we cannot request permissions.')));
  //     }
  //     return false;
  //   }
  //   return true;
  // }

  // This method is kept for future use but commented out to avoid unused code warnings
  // Future<void> _getCurrentPosition() async {
  //   final hasPermission = await _handleLocationPermission();
  //
  //   if (!hasPermission) return;
  //   await Geolocator.getCurrentPosition(
  //     locationSettings: const LocationSettings(
  //       accuracy: LocationAccuracy.high,
  //     ),
  //   ).then((Position position) {
  //     setState(() => _currentPosition = position);
  //     _getAddressFromLatLng(_currentPosition!);
  //   }).catchError((e) {
  //     debugPrint(e.toString());
  //   });
  // }

  // This method is kept for future use but commented out to avoid unused code warnings
  // Future<void> _getAddressFromLatLng(Position position) async {
  //   await placemarkFromCoordinates(
  //           _currentPosition!.latitude, _currentPosition!.longitude)
  //       .then((List<Placemark> placemarks) {
  //     Placemark place = placemarks[0];
  //     setState(() {
  //       _currentAddress =
  //           '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
  //     });
  //   }).catchError((e) {
  //     debugPrint(e.toString());
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Location Page")),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('LAT: ${_currentPosition?.latitude ?? ""}'),
              Text('LNG: ${_currentPosition?.longitude ?? ""}'),
              Text('ADDRESS: ${_currentAddress ?? ""}'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  _messageController.sendLocationViaSMS("Medical Emergency");
                  // _getCurrentPosition();
                },
                child: const Text("Sent Distress Message With Location"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
