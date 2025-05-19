import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyDetailsController extends GetxController {
  static EmergencyDetailsController get instance => Get.find();

  final Rx<String> _selectedCondition = ''.obs;
  final RxList<String> _symptoms = <String>[].obs;
  final Rx<String> _additionalInfo = ''.obs;
  final RxBool _isConscious = true.obs;
  final RxBool _isBreathing = true.obs;
  final RxBool _isBleeding = false.obs;

  // Getters
  String get selectedCondition => _selectedCondition.value;
  List<String> get symptoms => _symptoms;
  String get additionalInfo => _additionalInfo.value;
  bool get isConscious => _isConscious.value;
  bool get isBreathing => _isBreathing.value;
  bool get isBleeding => _isBleeding.value;

  // Emergency type specific conditions
  Map<String, List<String>> emergencyTypeConditions = {
    'Medical Emergency': [
      'Cardiac Emergency',
      'Breathing Difficulty',
      'Severe Injury',
      'Stroke Symptoms',
      'Allergic Reaction',
      'Unconscious Person',
      'Seizure',
      'Other Medical Emergency'
    ],
    'Police Emergency': [
      'Assault/Violence',
      'Robbery/Theft',
      'Break-in',
      'Suspicious Activity',
      'Traffic Accident',
      'Public Disturbance',
      'Other Police Emergency'
    ],
    'Fire Emergency': [
      'Building Fire',
      'Vehicle Fire',
      'Forest/Bush Fire',
      'Gas Leak',
      'Chemical Fire',
      'Electrical Fire',
      'Smoke Detection',
      'Other Fire Emergency'
    ],
    'Crime Report': [
      'Theft',
      'Vandalism',
      'Harassment',
      'Domestic Violence',
      'Drug-related Activity',
      'Suspicious Behavior',
      'Other Crime'
    ]
  };

  // Emergency type specific symptoms
  Map<String, List<String>> emergencyTypeSymptoms = {
    'Medical Emergency': [
      'Chest Pain',
      'Difficulty Breathing',
      'Severe Bleeding',
      'Severe Pain',
      'Dizziness',
      'Confusion',
      'Weakness',
      'Fever',
      'Loss of Consciousness'
    ],
    'Police Emergency': [
      'Physical Injury',
      'Property Damage',
      'Theft of Property',
      'Verbal Threats',
      'Weapon Present',
      'Multiple Suspects',
      'Vehicle Involved'
    ],
    'Fire Emergency': [
      'Visible Flames',
      'Heavy Smoke',
      'Gas Smell',
      'Trapped People',
      'Spreading Rapidly',
      'Electrical Issues',
      'Chemical Involvement',
      'Structure Damage'
    ],
    'Crime Report': [
      'Physical Evidence',
      'Witness Present',
      'Security Camera',
      'Property Damaged',
      'Items Stolen',
      'Vehicle Involved',
      'Suspect Description'
    ]
  };

  // Get conditions based on emergency type
  List<String> getConditionsForType(String type) {
    return emergencyTypeConditions[type] ?? emergencyTypeConditions['Medical Emergency']!;
  }

  // Get symptoms based on emergency type
  List<String> getSymptomsForType(String type) {
    return emergencyTypeSymptoms[type] ?? emergencyTypeSymptoms['Medical Emergency']!;
  }

  void setCondition(String condition) {
    _selectedCondition.value = condition;
  }

  void toggleSymptom(String symptom) {
    if (_symptoms.contains(symptom)) {
      _symptoms.remove(symptom);
    } else {
      _symptoms.add(symptom);
    }
  }

  void setAdditionalInfo(String info) {
    _additionalInfo.value = info;
  }

  void toggleConsciousness(bool value) {
    _isConscious.value = value;
  }

  void toggleBreathing(bool value) {
    _isBreathing.value = value;
  }

  void toggleBleeding(bool value) {
    _isBleeding.value = value;
  }

  void clearDetails() {
    _selectedCondition.value = '';
    _symptoms.clear();
    _additionalInfo.value = '';
    _isConscious.value = true;
    _isBreathing.value = true;
    _isBleeding.value = false;
  }

  String generateEmergencyMessage() {
    final StringBuffer message = StringBuffer();
    message.writeln('EMERGENCY DETAILS:');
    message.writeln('Condition: ${selectedCondition.isEmpty ? 'Not Specified' : selectedCondition}');
    
    if (symptoms.isNotEmpty) {
      message.writeln('Observations: ${symptoms.join(', ')}');
    }
    
    message.writeln('Status:');
    message.writeln('- ${isConscious ? 'Conscious' : 'Unconscious'}');
    message.writeln('- ${isBreathing ? 'Breathing' : 'Not Breathing'}');
    message.writeln('- ${isBleeding ? 'Bleeding Present' : 'No Bleeding'}');
    
    if (additionalInfo.isNotEmpty) {
      message.writeln('Additional Details: $additionalInfo');
    }

    return message.toString();
  }

  Future<void> saveEmergencyDetails() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('last_condition', selectedCondition);
    prefs.setStringList('last_symptoms', symptoms);
    prefs.setString('last_additional_info', additionalInfo);
    prefs.setBool('last_conscious', isConscious);
    prefs.setBool('last_breathing', isBreathing);
    prefs.setBool('last_bleeding', isBleeding);
  }
}

