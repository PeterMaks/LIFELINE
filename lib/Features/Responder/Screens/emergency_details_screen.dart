import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';
import 'package:public_emergency_app/Features/Responder/Controllers/responder_assignment_controller.dart';
import 'package:public_emergency_app/models/emergency_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyDetailsScreen extends StatelessWidget {
  final EmergencyModel emergency;
  
  EmergencyDetailsScreen({
    Key? key,
    required this.emergency,
  }) : super(key: key);

  final ResponderAssignmentController controller = Get.find<ResponderAssignmentController>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(color),
        title: const Text('Emergency Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyHeader(),
            const SizedBox(height: 20),
            _buildLocationSection(),
            const SizedBox(height: 20),
            _buildContactSection(),
            const SizedBox(height: 20),
            _buildDetailsSection(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmergencyHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForEmergencyType(emergency.emergencyType),
                  color: _getColorForEmergencyType(emergency.emergencyType),
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emergency.emergencyType,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${emergency.status.toUpperCase()}',
                        style: TextStyle(
                          color: _getStatusColor(emergency.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Created: ${_formatDateTime(emergency.createdAt)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            if (emergency.updatedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.update, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Updated: ${_formatDateTime(emergency.updatedAt!)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLocationSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              emergency.address,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Coordinates: ${emergency.latitude.toStringAsFixed(6)}, ${emergency.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openMap(),
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildContactSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  emergency.userPhone,
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _callUser(),
                  icon: const Icon(Icons.call, color: Colors.green),
                  tooltip: 'Call User',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  emergency.additionalInfo?['userName'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailsSection() {
    // Get additional details
    final condition = emergency.additionalInfo?['condition'] as String? ?? '';
    final symptoms = emergency.additionalInfo?['symptoms'] as List<dynamic>? ?? [];
    final additionalInfo = emergency.additionalInfo?['additionalInfo'] as String? ?? '';
    final isConscious = emergency.additionalInfo?['isConscious'] as bool? ?? true;
    final isBreathing = emergency.additionalInfo?['isBreathing'] as bool? ?? true;
    final isBleeding = emergency.additionalInfo?['isBleeding'] as bool? ?? false;
    final description = emergency.additionalInfo?['description'] as String? ?? '';
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Emergency Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (condition.isNotEmpty) ...[
              _buildDetailItem('Condition', condition),
              const SizedBox(height: 8),
            ],
            if (symptoms.isNotEmpty) ...[
              _buildDetailItem('Symptoms', symptoms.join(', ')),
              const SizedBox(height: 8),
            ],
            if (emergency.emergencyType.toLowerCase().contains('medical')) ...[
              _buildDetailItem('Conscious', isConscious ? 'Yes' : 'No'),
              const SizedBox(height: 8),
              _buildDetailItem('Breathing', isBreathing ? 'Yes' : 'No'),
              const SizedBox(height: 8),
              _buildDetailItem('Bleeding', isBleeding ? 'Yes' : 'No'),
              const SizedBox(height: 8),
            ],
            if (description.isNotEmpty) ...[
              _buildDetailItem('Description', description),
              const SizedBox(height: 8),
            ],
            if (additionalInfo.isNotEmpty) ...[
              _buildDetailItem('Additional Information', additionalInfo),
            ],
            if (emergency.videoId != null && emergency.videoId!.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _viewLiveStream(),
                  icon: const Icon(Icons.videocam),
                  label: const Text('View Live Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    // Check if already assigned
    bool isAssigned = controller.assignedEmergencies.containsValue(emergency.id ?? '');
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isAssigned ? null : () => _assignToEmergency(),
            icon: const Icon(Icons.assignment_turned_in),
            label: const Text('Accept Emergency'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
  
  void _openMap() async {
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
  
  void _callUser() async {
    final url = 'tel:${emergency.userPhone}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      Get.snackbar(
        'Error',
        'Could not make call',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void _viewLiveStream() {
    // Implement live stream viewing
    Get.snackbar(
      'Live Stream',
      'Connecting to live stream...',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }
  
  void _assignToEmergency() async {
    if (emergency.id == null) {
      Get.snackbar(
        'Error',
        'Emergency ID not available',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    await controller.assignToEmergency(emergency.id!);
  }
  
  String _formatDateTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'assigned':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
