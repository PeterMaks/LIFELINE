import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A model class for handling GeoJSON data
class GeoJsonModel {
  final String type;
  final List<Feature> features;

  GeoJsonModel({
    required this.type,
    required this.features,
  });

  factory GeoJsonModel.fromJson(Map<String, dynamic> json) {
    return GeoJsonModel(
      type: json['type'],
      features: (json['features'] as List)
          .map((feature) => Feature.fromJson(feature))
          .toList(),
    );
  }

  factory GeoJsonModel.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return GeoJsonModel.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'features': features.map((feature) => feature.toJson()).toList(),
    };
  }

  /// Convert GeoJSON features to Google Maps markers
  Set<Marker> toMarkers({
    required Function(Feature) onTap,
    BitmapDescriptor? icon,
  }) {
    return features
        .where((feature) => feature.geometry.type == 'Point')
        .map((feature) {
      final coordinates = feature.geometry.coordinates;
      final position = LatLng(coordinates[1], coordinates[0]);

      return Marker(
        markerId: MarkerId(feature.id ??
            feature.properties['id']?.toString() ??
            position.toString()),
        position: position,
        infoWindow: InfoWindow(
          title: feature.properties['title'] ?? feature.properties['name'],
          snippet: feature.properties['description'],
        ),
        icon: icon ?? BitmapDescriptor.defaultMarker,
        onTap: () => onTap(feature),
      );
    }).toSet();
  }

  /// Convert GeoJSON features to Google Maps polylines
  Set<Polyline> toPolylines({
    required String id,
    Color color = const Color(0xFF0000FF),
    int width = 5,
  }) {
    return features
        .where((feature) => feature.geometry.type == 'LineString')
        .map((feature) {
      final List<dynamic> coordinates = feature.geometry.coordinates;
      final List<LatLng> points =
          coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

      return Polyline(
        polylineId: PolylineId(
            '${id}_${feature.id ?? feature.properties['id'] ?? coordinates.hashCode}'),
        points: points,
        color: color,
        width: width,
      );
    }).toSet();
  }

  /// Convert GeoJSON features to Google Maps polygons
  Set<Polygon> toPolygons({
    required String id,
    Color fillColor = const Color(0x7F0000FF),
    Color strokeColor = const Color(0xFF0000FF),
    int strokeWidth = 2,
  }) {
    return features
        .where((feature) => feature.geometry.type == 'Polygon')
        .map((feature) {
      final List<dynamic> coordinates = feature.geometry.coordinates[0];
      final List<LatLng> points =
          coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

      return Polygon(
        polygonId: PolygonId(
            '${id}_${feature.id ?? feature.properties['id'] ?? coordinates.hashCode}'),
        points: points,
        fillColor: fillColor,
        strokeColor: strokeColor,
        strokeWidth: strokeWidth,
      );
    }).toSet();
  }
}

class Feature {
  final String? id;
  final String type;
  final Geometry geometry;
  final Map<String, dynamic> properties;

  Feature({
    this.id,
    required this.type,
    required this.geometry,
    required this.properties,
  });

  factory Feature.fromJson(Map<String, dynamic> json) {
    return Feature(
      id: json['id'],
      type: json['type'],
      geometry: Geometry.fromJson(json['geometry']),
      properties: json['properties'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'geometry': geometry.toJson(),
      'properties': properties,
    };
  }
}

class Geometry {
  final String type;
  final dynamic coordinates;

  Geometry({
    required this.type,
    required this.coordinates,
  });

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      type: json['type'],
      coordinates: json['coordinates'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'coordinates': coordinates,
    };
  }
}
