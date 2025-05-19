import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/User/Controllers/emergency_creation_controller.dart';
import 'package:public_emergency_app/Features/User/Controllers/emergency_details_controller.dart';
import 'package:public_emergency_app/Features/User/Screens/LiveStreaming/live_stream.dart';
import 'package:public_emergency_app/utils/logger_util.dart';

class EmergencyCreationScreen extends StatelessWidget {
  final String initialEmergencyType;

  EmergencyCreationScreen({
    Key? key,
    required this.initialEmergencyType,
  }) : super(key: key);

  final EmergencyCreationController controller =
      Get.put(EmergencyCreationController());
  final EmergencyDetailsController detailsController =
      Get.put(EmergencyDetailsController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // Initialize controller with the emergency type
    controller.emergencyType.value = initialEmergencyType;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(color),
        title: const Text('Create Emergency Alert'),
        centerTitle: true,
      ),
      body: Obx(() => controller.isCreatingEmergency.value
          ? _buildLoadingView()
          : _buildForm(context)),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Creating emergency alert...',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 10),
          Text(
            'Please wait while we process your request',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyTypeSection(),
            const SizedBox(height: 20),
            _buildLocationSection(),
            const SizedBox(height: 20),
            _buildDetailsSection(),
            const SizedBox(height: 20),
            _buildOptionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(
                _getIconForEmergencyType(controller.emergencyType.value),
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.emergencyType.value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requesting ${controller.emergencyType.value} assistance',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => controller.getCurrentLocation(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Obx(() => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: controller.isLocationLoading.value
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                controller.currentAddress.value.isEmpty
                                    ? 'Tap refresh to get your current location'
                                    : controller.currentAddress.value,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (controller.currentPosition.value != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Coordinates: ${controller.currentPosition.value!.latitude.toStringAsFixed(6)}, '
                            '${controller.currentPosition.value!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
            )),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Condition Dropdown
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Emergency Condition',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.medical_information),
          ),
          value: detailsController.selectedCondition.isEmpty
              ? null
              : detailsController.selectedCondition,
          items: detailsController
              .getConditionsForType(controller.emergencyType.value)
              .map((condition) => DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              detailsController.setCondition(value);
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a condition';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Description TextField
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Additional Description',
            hintText: 'Provide any additional details about the emergency',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: const Icon(Icons.description),
          ),
          maxLines: 3,
          onChanged: (value) => controller.emergencyDescription.value = value,
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Send SMS Option
        Obx(() => SwitchListTile(
              title: const Text('Send SMS to Emergency Contacts'),
              subtitle: const Text(
                  'Notify your emergency contacts about this situation'),
              value: controller.sendSmsToContacts.value,
              onChanged: (value) => controller.sendSmsToContacts.value = value,
              secondary: const Icon(Icons.message),
            )),

        // Live Stream Option
        Obx(() => SwitchListTile(
              title: const Text('Start Live Stream'),
              subtitle: const Text('Stream video to emergency responders'),
              value: controller.startLiveStream.value,
              onChanged: (value) => controller.startLiveStream.value = value,
              secondary: const Icon(Icons.videocam),
            )),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Color(color)),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _submitEmergency(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Send Alert'),
            ),
          ),
        ],
      ),
    );
  }

  void _submitEmergency() async {
    try {
      // Check if form is valid
      if (!_formKey.currentState!.validate()) {
        Get.snackbar(
          'Validation Error',
          'Please fill in all required fields',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Check if location is available
      if (controller.currentPosition.value == null) {
        bool locationSuccess = await controller.getCurrentLocation();
        if (!locationSuccess) {
          Get.snackbar(
            'Location Required',
            'We need your location to send emergency services. Please tap the refresh button in the location section.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          return;
        }
      }

      // Save emergency details for future reference
      detailsController.saveEmergencyDetails();

      // Create emergency
      bool success = await controller.createEmergency();

      if (success) {
        Get.snackbar(
          'Success',
          'Emergency alert sent successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Start live stream if selected
        if (controller.startLiveStream.value) {
          Get.to(() => LiveStreamingPage(
                isHost: true,
                liveId: controller.emergencyId.value,
              ));
        } else {
          Get.back();
        }
      }
    } catch (e) {
      LoggerUtil.error('Error submitting emergency', e);
      Get.snackbar(
        'Error',
        'An unexpected error occurred. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  IconData _getIconForEmergencyType(String type) {
    switch (type) {
      case 'Medical Emergency':
        return Icons.medical_services;
      case 'Police Emergency':
        return Icons.local_police;
      case 'Fire Emergency':
        return Icons.local_fire_department;
      case 'Crime Report':
        return Icons.report_problem;
      default:
        return Icons.emergency;
    }
  }
}
