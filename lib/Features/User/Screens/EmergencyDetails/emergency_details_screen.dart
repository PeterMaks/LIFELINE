import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../Common Widgets/constants.dart';
import '../../Controllers/emergency_details_controller.dart';
import '../../Controllers/message_sending.dart';

class EmergencyDetailsScreen extends StatelessWidget {
  final String emergencyType;
  EmergencyDetailsScreen({Key? key, required this.emergencyType}) : super(key: key);

  final EmergencyDetailsController controller = Get.put(EmergencyDetailsController());
  final MessageController msgController = Get.put(MessageController());
  final RxBool _isLoading = false.obs;

  bool _validateForm() {
    if (controller.selectedCondition.isEmpty) {
      Get.snackbar(
        'Missing Information',
        'Please select an emergency condition',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    if (controller.symptoms.isEmpty) {
      Get.snackbar(
        'Missing Information',
        emergencyType.contains('Medical') 
          ? 'Please select at least one symptom'
          : 'Please select at least one observation',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    return true;
  }

  Future<void> _sendEmergencyMessage() async {
    if (!_validateForm()) return;

    try {
      _isLoading.value = true;
      await msgController.sendLocationViaSMS(emergencyType);
      await controller.saveEmergencyDetails();
      Get.back();
      Get.snackbar(
        'Success',
        'Emergency message sent successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send emergency message. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Widget _buildSendButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        onPressed: _isLoading.value ? null : _sendEmergencyMessage,
        child: _isLoading.value
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
              'SEND EMERGENCY MESSAGE',
              style: TextStyle(fontSize: 18),
            ),
      ),
    ));
  }
  @override
  Widget build(BuildContext context) {
    // Clear previous details when screen loads
    controller.clearDetails();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(color),
        title: const Text('Emergency Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Type: $emergencyType',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            
            // Condition Dropdown
            const Text('Select Emergency Condition:', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            Obx(() => DropdownButton<String>(
              isExpanded: true,
              value: controller.selectedCondition.isEmpty ? null : controller.selectedCondition,
              hint: const Text('Select Condition'),
              items: controller.getConditionsForType(emergencyType).map((String condition) {
                return DropdownMenuItem<String>(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) controller.setCondition(value);
              },
            )),
            
            const SizedBox(height: 20),
            
            // Symptoms/Observations MultiSelect
            Text(
              emergencyType.contains('Medical') ? 'Select Symptoms:' : 'Select Observations:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            Obx(() => Wrap(
              spacing: 8.0,
              children: controller.getSymptomsForType(emergencyType).map((symptom) {
                return FilterChip(
                  label: Text(symptom),
                  selected: controller.symptoms.contains(symptom),
                  onSelected: (bool selected) {
                    controller.toggleSymptom(symptom);
                  },
                );
              }).toList(),
            )),
            
            const SizedBox(height: 20),
            
            // Status Toggles - Show only for medical emergencies
            if (emergencyType.contains('Medical')) ...[
              const Text('Patient Status:', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              Obx(() => SwitchListTile(
                title: const Text('Is Conscious'),
                value: controller.isConscious,
                onChanged: controller.toggleConsciousness,
              )),
              Obx(() => SwitchListTile(
                title: const Text('Is Breathing'),
                value: controller.isBreathing,
                onChanged: controller.toggleBreathing,
              )),
              Obx(() => SwitchListTile(
                title: const Text('Is Bleeding'),
                value: controller.isBleeding,
                onChanged: controller.toggleBleeding,
              )),
            ],
            
            const SizedBox(height: 20),
            
            // Additional Information
            const Text('Additional Information:', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
            ),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter any additional details about the emergency',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.setAdditionalInfo,
            ),
            
            const SizedBox(height: 30),
            
            // Send Emergency Message Button
            _buildSendButton(),
          ],
        ),
      ),
    );
  }
}
