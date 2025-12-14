import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LatLngResult {
  final double lat;
  final double lng;
  final String? displayName;

  LatLngResult({required this.lat, required this.lng, this.displayName});
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _controller;
  LatLng _center = const LatLng(23.6102, 85.2799); // Example: Jharkhand
  LatLng? _picked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pick Location",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _picked == null
                ? null
                : () {
                    Navigator.pop(
                      context,
                      LatLngResult(
                        lat: _picked!.latitude,
                        lng: _picked!.longitude,
                      ),
                    );
                  },
            child: const Text("Done"),
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 12,
        ),
        onMapCreated: (c) => _controller = c,
        onTap: (latLng) {
          setState(() {
            _picked = latLng;
          });
        },
        markers: {
          if (_picked != null)
            Marker(
              markerId: const MarkerId("picked"),
              position: _picked!,
            ),
        },
      ),
    );
  }
}
