import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/Responder/Controllers/responder_assignment_controller.dart';
import 'package:public_emergency_app/Features/Responder/Screens/emergency_details_screen.dart';
import 'package:public_emergency_app/models/emergency_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyListScreen extends StatelessWidget {
  EmergencyListScreen({Key? key}) : super(key: key);

  final ResponderAssignmentController controller = Get.put(ResponderAssignmentController());
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(color),
        title: const Text('Nearby Emergencies'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshLocation(),
          ),
        ],
      ),
      body: Obx(() => _buildBody()),
    );
  }
  
  Widget _buildBody() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (controller.currentPosition.value == null) {
      return _buildLocationPrompt();
    }
    
    if (controller.activeEmergencies.isEmpty) {
      return _buildNoEmergenciesView();
    }
    
    final nearbyEmergencies = controller.getNearbyEmergencies();
    
    if (nearbyEmergencies.isEmpty) {
      return _buildNoNearbyEmergenciesView();
    }
    
    return _buildEmergencyList(nearbyEmergencies);
  }
  
  Widget _buildLocationPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Not Available',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We need your location to find nearby emergencies.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _refreshLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Get My Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(color),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoEmergenciesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Emergencies',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'There are currently no active emergencies in the system.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _refreshLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(color),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNoNearbyEmergenciesView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_searching,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'No Nearby Emergencies',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'There are no emergencies near your location or matching your responder type.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _refreshLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(color),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmergencyList(List<EmergencyModel> emergencies) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: emergencies.length,
      itemBuilder: (context, index) {
        final emergency = emergencies[index];
        return _buildEmergencyCard(emergency);
      },
    );
  }
  
  Widget _buildEmergencyCard(EmergencyModel emergency) {
    // Calculate distance
    double distance = 0;
    if (controller.currentPosition.value != null) {
      distance = Geolocator.distanceBetween(
        controller.currentPosition.value!.latitude,
        controller.currentPosition.value!.longitude,
        emergency.latitude,
        emergency.longitude
      );
    }
    
    // Format distance
    String distanceText = distance < 1000
        ? '${distance.toStringAsFixed(0)} m'
        : '${(distance / 1000).toStringAsFixed(1)} km';
    
    // Check if already assigned
    bool isAssigned = controller.assignedEmergencies.containsValue(emergency.id ?? '');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAssigned ? Colors.green : Colors.transparent,
          width: isAssigned ? 2 : 0,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(15),
            title: Row(
              children: [
                Icon(
                  _getIconForEmergencyType(emergency.emergencyType),
                  color: _getColorForEmergencyType(emergency.emergencyType),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    emergency.emergencyType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAssigned ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isAssigned ? 'Assigned' : distanceText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        emergency.address,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      _formatTimestamp(emergency.createdAt),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _viewEmergencyDetails(emergency),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMap(emergency),
                    icon: const Icon(Icons.map),
                    label: const Text('View Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isAssigned
                        ? null
                        : () => _assignToEmergency(emergency),
                    icon: Icon(isAssigned ? Icons.check : Icons.assignment_turned_in),
                    label: Text(isAssigned ? 'Assigned' : 'Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAssigned ? Colors.grey : Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.green,
                      disabledForegroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _refreshLocation() async {
    try {
      controller.isLoading.value = true;
      
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permission is required to find nearby emergencies',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          controller.isLoading.value = false;
          return;
        }
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      controller.currentPosition.value = position;
      controller.isLoading.value = false;
      
      // Update responder status
      await controller.updateResponderStatus(true);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get location: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      controller.isLoading.value = false;
    }
  }
  
  void _viewEmergencyDetails(EmergencyModel emergency) {
    Get.to(() => EmergencyDetailsScreen(emergency: emergency));
  }
  
  void _openMap(EmergencyModel emergency) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${emergency.latitude},${emergency.longitude}&travelmode=driving';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Error',
        'Could not open map',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void _assignToEmergency(EmergencyModel emergency) async {
    if (emergency.id == null) {
      Get.snackbar(
        'Error',
        'Emergency ID not available',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    bool success = await controller.assignToEmergency(emergency.id!);
    
    if (success) {
      _viewEmergencyDetails(emergency);
    }
  }
  
  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hr ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return timestamp;
    }
  }
  
  IconData _getIconForEmergencyType(String type) {
    if (type.toLowerCase().contains('medical')) {
      return Icons.medical_services;
    } else if (type.toLowerCase().contains('police') || 
               type.toLowerCase().contains('crime')) {
      return Icons.local_police;
    } else if (type.toLowerCase().contains('fire') || 
               type.toLowerCase().contains('gas')) {
      return Icons.local_fire_department;
    } else {
      return Icons.emergency;
    }
  }
  
  Color _getColorForEmergencyType(String type) {
    if (type.toLowerCase().contains('medical')) {
      return Colors.red;
    } else if (type.toLowerCase().contains('police') || 
               type.toLowerCase().contains('crime')) {
      return Colors.blue;
    } else if (type.toLowerCase().contains('fire') || 
               type.toLowerCase().contains('gas')) {
      return Colors.orange;
    } else {
      return Colors.purple;
    }
  }
}
