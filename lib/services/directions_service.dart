import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectionsService {
  final String apiKey;

  DirectionsService({required this.apiKey});

  Future<List<LatLng>> getDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    final String url = 
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);

    var results = {
      'polyline_decoded': PolylinePoints().decodePolyline(json['routes'][0]['overview_polyline']['points'])
    };

    List<LatLng> polylineCoordinates = [];
    if (results['polyline_decoded']!.isNotEmpty) {
      for (var point in results['polyline_decoded']!) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    return polylineCoordinates;
  }
}
