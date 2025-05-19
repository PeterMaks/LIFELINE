import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:public_emergency_app/Common%20Widgets/constants.dart';

class ExtendedProfileScreen extends StatefulWidget {
  const ExtendedProfileScreen({Key? key}) : super(key: key);

  @override
  State<ExtendedProfileScreen> createState() => _ExtendedProfileScreenState();
}

class _ExtendedProfileScreenState extends State<ExtendedProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  
  // User data
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userType = '';
  
  // Medical info controllers
  final bloodTypeController = TextEditingController();
  final allergiesController = TextEditingController();
  final medicationsController = TextEditingController();
  final medicalConditionsController = TextEditingController();
  final emergencyNotesController = TextEditingController();
  
  // Settings
  bool notificationsEnabled = true;
  bool locationSharingEnabled = true;
  bool darkModeEnabled = false;
  
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    bloodTypeController.dispose();
    allergiesController.dispose();
    medicationsController.dispose();
    medicalConditionsController.dispose();
    emergencyNotesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      final snapshot = await _database.child('Users').child(uid).get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        setState(() {
          userName = data['UserName'] ?? '';
          userEmail = data['email'] ?? '';
          userPhone = data['Phone'] ?? '';
          userType = data['UserType'] ?? '';
          
          // Load medical info if available
          if (data['medicalInfo'] != null) {
            final medicalInfo = data['medicalInfo'] as Map<dynamic, dynamic>;
            bloodTypeController.text = medicalInfo['bloodType'] ?? '';
            allergiesController.text = medicalInfo['allergies'] ?? '';
            medicationsController.text = medicalInfo['medications'] ?? '';
            medicalConditionsController.text = medicalInfo['medicalConditions'] ?? '';
            emergencyNotesController.text = medicalInfo['emergencyNotes'] ?? '';
          }
          
          // Load settings if available
          if (data['settings'] != null) {
            final settings = data['settings'] as Map<dynamic, dynamic>;
            notificationsEnabled = settings['notificationsEnabled'] ?? true;
            locationSharingEnabled = settings['locationSharingEnabled'] ?? true;
            darkModeEnabled = settings['darkModeEnabled'] ?? false;
          }
        });
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load user data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        Get.snackbar(
          'Error',
          'User not authenticated',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      // Update medical info
      await _database.child('Users').child(uid).update({
        'medicalInfo': {
          'bloodType': bloodTypeController.text,
          'allergies': allergiesController.text,
          'medications': medicationsController.text,
          'medicalConditions': medicalConditionsController.text,
          'emergencyNotes': emergencyNotesController.text,
        },
        'settings': {
          'notificationsEnabled': notificationsEnabled,
          'locationSharingEnabled': locationSharingEnabled,
          'darkModeEnabled': darkModeEnabled,
        },
        'profileComplete': true,
        'updatedAt': DateTime.now().toString(),
      });
      
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save user data: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extended Profile'),
        backgroundColor: Color(color),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Basic Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                title: const Text('Name'),
                                subtitle: Text(userName),
                                leading: const Icon(Icons.person),
                              ),
                              ListTile(
                                title: const Text('Email'),
                                subtitle: Text(userEmail),
                                leading: const Icon(Icons.email),
                              ),
                              ListTile(
                                title: const Text('Phone'),
                                subtitle: Text(userPhone),
                                leading: const Icon(Icons.phone),
                              ),
                              ListTile(
                                title: const Text('User Type'),
                                subtitle: Text(userType == 'emergency_responder'
                                    ? 'Emergency Responder'
                                    : 'Civilian'),
                                leading: const Icon(Icons.badge),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Medical Info Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Medical Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: bloodTypeController,
                                decoration: const InputDecoration(
                                  labelText: 'Blood Type',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: allergiesController,
                                decoration: const InputDecoration(
                                  labelText: 'Allergies',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: medicationsController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Medications',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: medicalConditionsController,
                                decoration: const InputDecoration(
                                  labelText: 'Medical Conditions',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: emergencyNotesController,
                                decoration: const InputDecoration(
                                  labelText: 'Emergency Notes',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Settings Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text('Enable Notifications'),
                                value: notificationsEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    notificationsEnabled = value;
                                  });
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Share Location'),
                                value: locationSharingEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    locationSharingEnabled = value;
                                  });
                                },
                              ),
                              SwitchListTile(
                                title: const Text('Dark Mode'),
                                value: darkModeEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    darkModeEnabled = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(color),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _saveUserData,
                          child: const Text('SAVE PROFILE'),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
