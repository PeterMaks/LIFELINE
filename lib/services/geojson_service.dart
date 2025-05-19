import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:public_emergency_app/models/geojson_model.dart';
import 'package:public_emergency_app/utils/logger_util.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service for handling GeoJSON data
class GeoJsonService {
  /// Fetch GeoJSON data from a URL
  Future<GeoJsonModel?> fetchGeoJsonFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return GeoJsonModel.fromJson(data);
      } else {
        LoggerUtil.error('Failed to load GeoJSON data: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggerUtil.error('Error fetching GeoJSON data', e);
      return null;
    }
  }

  /// Convert Firebase emergency data to GeoJSON
  Future<GeoJsonModel> convertEmergenciesToGeoJson() async {
    try {
      // Get emergencies from Firebase
      final DatabaseReference sosRef = FirebaseDatabase.instance.ref().child('sos');
      final DatabaseEvent event = await sosRef.once();
      
      if (!event.snapshot.exists) {
        return _createEmptyGeoJson();
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Feature> features = [];
      
      // Convert each emergency to a GeoJSON feature
      data.forEach((key, value) {
        if (value is Map && value.containsKey('lat') && value.containsKey('long')) {
          final double lat = double.tryParse(value['lat'].toString()) ?? 0.0;
          final double long = double.tryParse(value['long'].toString()) ?? 0.0;
          
          if (lat != 0.0 && long != 0.0) {
            features.add(Feature(
              id: key,
              type: 'Feature',
              geometry: Geometry(
                type: 'Point',
                coordinates: [long, lat],
              ),
              properties: {
                'title': 'Emergency',
                'description': value['address'] ?? 'No address',
                'emergencyType': value['emergencyType'] ?? 'Unknown',
                'status': value['status'] ?? 'active',
                'createdAt': value['createdAt'] ?? value['time'] ?? 'Unknown',
                'address': value['address'] ?? 'No address',
              },
            ));
          }
        }
      });
      
      return GeoJsonModel(
        type: 'FeatureCollection',
        features: features,
      );
    } catch (e) {
      LoggerUtil.error('Error converting emergencies to GeoJSON', e);
      return _createEmptyGeoJson();
    }
  }

  /// Convert Firebase responder data to GeoJSON
  Future<GeoJsonModel> convertRespondersToGeoJson() async {
    try {
      // Get active responders from Firebase
      final DatabaseReference respondersRef = FirebaseDatabase.instance.ref().child('activeResponders');
      final DatabaseEvent event = await respondersRef.once();
      
      if (!event.snapshot.exists) {
        return _createEmptyGeoJson();
      }
      
      final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      final List<Feature> features = [];
      
      // Convert each responder to a GeoJSON feature
      data.forEach((key, value) {
        if (value is Map && (value.containsKey('lat') || value.containsKey('latitude')) && 
            (value.containsKey('long') || value.containsKey('longitude'))) {
          
          final double lat = double.tryParse(value['lat']?.toString() ?? value['latitude']?.toString() ?? '0.0') ?? 0.0;
          final double long = double.tryParse(value['long']?.toString() ?? value['longitude']?.toString() ?? '0.0') ?? 0.0;
          
          if (lat != 0.0 && long != 0.0) {
            features.add(Feature(
              id: key,
              type: 'Feature',
              geometry: Geometry(
                type: 'Point',
                coordinates: [long, lat],
              ),
              properties: {
                'title': 'Responder',
                'description': 'Active Responder',
                'responderType': value['responderType'] ?? 'Unknown',
                'status': value['status'] ?? 'available',
                'timestamp': value['timestamp'] ?? 'Unknown',
              },
            ));
          }
        }
      });
      
      return GeoJsonModel(
        type: 'FeatureCollection',
        features: features,
      );
    } catch (e) {
      LoggerUtil.error('Error converting responders to GeoJSON', e);
      return _createEmptyGeoJson();
    }
  }

  /// Create an empty GeoJSON object
  GeoJsonModel _createEmptyGeoJson() {
    return GeoJsonModel(
      type: 'FeatureCollection',
      features: [],
    );
  }
}
