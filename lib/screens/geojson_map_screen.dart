import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:public_emergency_app/controllers/geojson_map_controller.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';

class GeoJsonMapScreen extends StatelessWidget {
  final GeoJsonMapController controller = Get.put(GeoJsonMapController());

  GeoJsonMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Map'),
        backgroundColor: Color(color),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.animateToCurrentLocation();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: controller.initialPosition.value,
                zoom: 14.0,
              ),
              markers: controller.markers,
              polylines: controller.polylines,
              polygons: controller.polygons,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: true,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController mapController) {
                if (!controller.mapController.isCompleted) {
                  controller.mapController.complete(mapController);
                }
              },
            ),
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'location',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    child: const Icon(Icons.my_location),
                    onPressed: () {
                      controller.animateToCurrentLocation();
                    },
                  ),
                  const SizedBox(height: 8.0),
                  FloatingActionButton(
                    heroTag: 'emergencies',
                    backgroundColor: Colors.white,
                    foregroundColor: controller.showEmergencies.value ? Colors.red : Colors.grey,
                    child: const Icon(Icons.emergency),
                    onPressed: () {
                      controller.toggleEmergencies();
                    },
                  ),
                  const SizedBox(height: 8.0),
                  FloatingActionButton(
                    heroTag: 'responders',
                    backgroundColor: Colors.white,
                    foregroundColor: controller.showResponders.value ? Colors.green : Colors.grey,
                    child: const Icon(Icons.local_police),
                    onPressed: () {
                      controller.toggleResponders();
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16.0,
              left: 16.0,
              right: 16.0,
              child: Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Map Legend',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Row(
                              children: [
                                Container(
                                  width: 12.0,
                                  height: 12.0,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                const Text('Your Location'),
                                const SizedBox(width: 8.0),
                                Container(
                                  width: 12.0,
                                  height: 12.0,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                const Text('Emergencies'),
                                const SizedBox(width: 8.0),
                                Container(
                                  width: 12.0,
                                  height: 12.0,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 4.0),
                                const Text('Responders'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
