import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:public_emergency_app/models/geojson_model.dart';
import 'package:public_emergency_app/services/geojson_service.dart';
import 'package:public_emergency_app/utils/logger_util.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class GeoJsonMapController extends GetxController {
  // Services
  final GeoJsonService _geoJsonService = GeoJsonService();
  
  // Observables
  final Rx<GeoJsonModel?> emergenciesGeoJson = Rx<GeoJsonModel?>(null);
  final Rx<GeoJsonModel?> respondersGeoJson = Rx<GeoJsonModel?>(null);
  final RxSet<Marker> markers = <Marker>{}.obs;
  final RxSet<Polyline> polylines = <Polyline>{}.obs;
  final RxSet<Polygon> polygons = <Polygon>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool showEmergencies = true.obs;
  final RxBool showResponders = true.obs;
  
  // Map controller
  Completer<GoogleMapController> mapController = Completer<GoogleMapController>();
  
  // Current position
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final Rx<LatLng> initialPosition = Rx<LatLng>(const LatLng(0, 0));
  
  // Firebase references for real-time updates
  late final DatabaseReference sosRef;
  late final DatabaseReference respondersRef;
  late final StreamSubscription<DatabaseEvent> sosSubscription;
  late final StreamSubscription<DatabaseEvent> respondersSubscription;
  
  @override
  void onInit() {
    super.onInit();
    _initializeReferences();
    _getCurrentLocation();
    _setupListeners();
  }
  
  @override
  void onClose() {
    sosSubscription.cancel();
    respondersSubscription.cancel();
    super.onClose();
  }
  
  void _initializeReferences() {
    sosRef = FirebaseDatabase.instance.ref().child('sos');
    respondersRef = FirebaseDatabase.instance.ref().child('activeResponders');
  }
  
  void _setupListeners() {
    // Listen for emergency changes
    sosSubscription = sosRef.onValue.listen((event) {
      _loadEmergencies();
    });
    
    // Listen for responder changes
    respondersSubscription = respondersRef.onValue.listen((event) {
      _loadResponders();
    });
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLoading.value = false;
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLoading.value = false;
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        isLoading.value = false;
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      currentPosition.value = position;
      initialPosition.value = LatLng(position.latitude, position.longitude);
      
      // Load data after getting location
      await _loadEmergencies();
      await _loadResponders();
      
      isLoading.value = false;
    } catch (e) {
      LoggerUtil.error('Error getting current location', e);
      isLoading.value = false;
    }
  }
  
  Future<void> _loadEmergencies() async {
    try {
      emergenciesGeoJson.value = await _geoJsonService.convertEmergenciesToGeoJson();
      _updateMapData();
    } catch (e) {
      LoggerUtil.error('Error loading emergencies', e);
    }
  }
  
  Future<void> _loadResponders() async {
    try {
      respondersGeoJson.value = await _geoJsonService.convertRespondersToGeoJson();
      _updateMapData();
    } catch (e) {
      LoggerUtil.error('Error loading responders', e);
    }
  }
  
  void _updateMapData() {
    final Set<Marker> newMarkers = {};
    
    // Add current location marker
    if (currentPosition.value != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Your Location',
        ),
      ));
    }
    
    // Add emergency markers
    if (showEmergencies.value && emergenciesGeoJson.value != null) {
      newMarkers.addAll(emergenciesGeoJson.value!.toMarkers(
        onTap: (feature) {
          // Handle emergency tap
          Get.snackbar(
            feature.properties['title'] ?? 'Emergency',
            feature.properties['description'] ?? 'No description',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    
    // Add responder markers
    if (showResponders.value && respondersGeoJson.value != null) {
      newMarkers.addAll(respondersGeoJson.value!.toMarkers(
        onTap: (feature) {
          // Handle responder tap
          Get.snackbar(
            feature.properties['title'] ?? 'Responder',
            feature.properties['description'] ?? 'No description',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    
    markers.value = newMarkers;
  }
  
  void toggleEmergencies() {
    showEmergencies.value = !showEmergencies.value;
    _updateMapData();
  }
  
  void toggleResponders() {
    showResponders.value = !showResponders.value;
    _updateMapData();
  }
  
  Future<void> animateToCurrentLocation() async {
    if (currentPosition.value != null && mapController.isCompleted) {
      final GoogleMapController controller = await mapController.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(currentPosition.value!.latitude, currentPosition.value!.longitude),
        15.0,
      ));
    }
  }
}
