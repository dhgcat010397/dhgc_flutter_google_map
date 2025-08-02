import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:dhgc_flutter_google_map/src/core/utils/constants/env_variables.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  final Location locationController = Location();

  static const LatLng googlePlex = LatLng(37.7749, -122.4194);
  static const LatLng mountainView = LatLng(37.3861, -122.0839);
  static const double initialZoom = 13;

  static const CameraPosition initialCameraPosition = CameraPosition(
    target: googlePlex, // Example coordinates (San Francisco)
    zoom: initialZoom,
  );

  final Marker markerSource = Marker(
    markerId: MarkerId('sourceLocation'),
    position: googlePlex,
    infoWindow: InfoWindow(title: 'Google Plex'),
    icon: BitmapDescriptor.defaultMarker,
  );
  final Marker markerDestination = Marker(
    markerId: MarkerId('destinationLocation'),
    position: mountainView,
    infoWindow: InfoWindow(title: 'Mountain View'),
    icon: BitmapDescriptor.defaultMarker,
  );
  late Set<Marker> markers;

  LatLng? currentPosition; // Current position of the user
  Map<PolylineId, Polyline> polylines = {};

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  List<LatLng> polylineCoordinates = [
    LatLng(10.7769, 106.7009), // District 1 - Ben Thanh Market
    LatLng(10.762622, 106.660172), // District 3 - War Remnants Museum
    LatLng(10.776530, 106.695800), // District 1 - Notre Dame Cathedral
    LatLng(10.762913, 106.682171), // District 3 - Tao Dan Park
    LatLng(10.823099, 106.629664), // Go Vap District
    LatLng(10.762389, 106.681145), // District 3 - Independence Palace
    LatLng(10.762835, 106.679983), // District 3 - Turtle Lake
    LatLng(10.754666, 106.639389), // District 5 - Cho Lon
    LatLng(10.776373, 106.701755), // District 1 - Saigon Opera House
    LatLng(10.800233, 106.714722), // Binh Thanh District - Landmark 81
  ];

  @override
  void initState() {
    super.initState();

    // Initialize Google Maps or any other setup needed
    markers = {markerSource, markerDestination};

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Fetch location updates after the first frame is rendered
      await initializeMap();
    });
  }

  Future<void> initializeMap() async {
    await fetchLocationUpdates();
    final coordinates = await fetchPolylinePoints();
    generatePolylineFromPoints(coordinates);
  }

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) return false;
    }

    permissionGranted = await locationController.hasPermission();
    if (permissionGranted == PermissionStatus.deniedForever) {
      // Permission denied forever, show a message or redirect to settings
      return false;
    }
    if (permissionGranted == PermissionStatus.denied ||
        permissionGranted == PermissionStatus.grantedLimited) {
      permissionGranted = await locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted &&
          permissionGranted != PermissionStatus.grantedLimited) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          LatLng? currentLocation = await _getCurrentLocation();
          // Optionally, you can also show the current location on the map
          if (currentLocation != null) {
            _addMarker(
              id: 'currentLocation',
              position: currentLocation,
              title: 'Current Location',
            );
            _moveCamera(currentLocation);
          }
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, size: 30),
      ),
      body:
          currentPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                initialCameraPosition: initialCameraPosition,
                markers: markers,
                polylines: Set<Polyline>.of(polylines.values),
                myLocationButtonEnabled: false,
                onMapCreated: _onMapCreated,
              ),
    );
  }

  Future<void> fetchLocationUpdates() async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      return;
    }

    locationController.onLocationChanged.listen((LocationData currentLocation) {
      // Handle location updates
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        // Update the map or markers with the new location
        // currentPosition = LatLng(
        //   currentLocation.latitude!,
        //   currentLocation.longitude!,
        // );
        _moveCamera(
          LatLng(currentLocation.latitude!, currentLocation.longitude!),
        );
        _addMarker(
          id: 'currentLocation',
          position: currentPosition!,
          title: 'Current Location',
        );
      }
      debugPrint(
        'Current location: ${currentPosition!.latitude}, ${currentPosition!.longitude}',
      );
    });
  }

  Future<List<LatLng>> fetchPolylinePoints() async {
    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: EnvVariables.apiKeyGoogleMaps,
    );

    PointLatLng origin = PointLatLng(
      polylineCoordinates.first.latitude,
      polylineCoordinates.first.longitude,
    );
    PointLatLng destination = PointLatLng(
      polylineCoordinates.last.latitude,
      polylineCoordinates.last.longitude,
    );

    RoutesApiRequest routesRequest = RoutesApiRequest(
      origin: origin,
      destination: destination,
      travelMode: TravelMode.driving,
      routingPreference: RoutingPreference.trafficAware,
      departureTime: DateTime.now().add(Duration(hours: 1)),
      // OR
      // arrivalTime: DateTime.now().add(Duration(hours: 2)),
    );

    // Convert Routes API response to legacy format
    RoutesApiResponse routesResponse = await polylinePoints
        .getRouteBetweenCoordinatesV2(request: routesRequest);

    PolylineResult legacyResult = polylinePoints.convertToLegacyResult(
      routesResponse,
    );

    if (legacyResult.points.isNotEmpty) {
      return legacyResult.points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    }

    return [];
  }

  Future<void> generatePolylineFromPoints(
    List<LatLng> polylineCoordinates,
  ) async {
    PolylineId polylineId = PolylineId('polyline_id');
    Polyline polyline = Polyline(
      polylineId: polylineId,
      color: Colors.blueAccent,
      width: 5,
      points: polylineCoordinates,
    );

    if (mounted) {
      setState(() {
        polylines[polylineId] = polyline;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    // Handle map creation logic here
    _controller.complete(controller);
  }

  Future<LatLng?> _getCurrentLocation() async {
    bool hasPermission = await requestPermission();
    if (!hasPermission) {
      return null;
    }

    Location location = Location();
    try {
      final currentLocation = await location.getLocation();
      // Use currentLocation to update the map or markers
      return LatLng(
        currentLocation.latitude ?? 0,
        currentLocation.longitude ?? 0,
      );
    } catch (e) {
      // Handle error
      debugPrint('Error getting current location: $e');
    }

    return null;
  }

  Future<void> _addMarker({
    required String id,
    required LatLng position,
    String? title = 'New Marker',
    BitmapDescriptor? icon = BitmapDescriptor.defaultMarker,
  }) async {
    final markerId = MarkerId(id);
    // Check if the marker already exists
    if (markers.any((m) => m.markerId == markerId)) {
      _removeMarker(markerId);
    }
    final marker = Marker(
      markerId: markerId,
      position: position,
      infoWindow: InfoWindow(title: title),
      icon: icon!,
    );

    if (mounted) {
      setState(() {
        markers.add(marker);
      });
    }
  }

  Future<void> _removeMarker(MarkerId markerId) async {
    if (mounted) {
      setState(() {
        markers.removeWhere((marker) => marker.markerId == markerId);
      });
    }
  }

  Future<void> _moveCamera(LatLng position) async {
    final GoogleMapController controller =
        _controller.future as GoogleMapController;
    CameraPosition cameraPosition = CameraPosition(
      target: position,
      zoom: initialZoom,
    );

    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    if (mounted) {
      setState(() {
        currentPosition = position;
      });
    }
  }

  // Future<void> _showMyLocation() async {
  //   final GoogleMapController controller = await GoogleMapController.init();
  //   final Location location = Location();
  //   final currentLocation = await location.getLocation();

  //   controller.animateCamera(
  //     CameraUpdate.newLatLngZoom(
  //       LatLng(currentLocation.latitude ?? 0, currentLocation.longitude ?? 0),
  //       initialZoom,
  //     ),
  //   );
  // }
}
