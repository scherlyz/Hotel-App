import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';

class MapScreen extends StatefulWidget {
  final Place place;

  const MapScreen({super.key, required this.place});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _userPosition;
  bool _loadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'GPS tidak aktif. Aktifkan GPS untuk melihat lokasi kamu.';
          _loadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Izin lokasi ditolak.';
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Izin lokasi ditolak permanen. Aktifkan di Settings.';
          _loadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _userPosition = position;
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Gagal mendapatkan lokasi: $e';
        _loadingLocation = false;
      });
    }
  }

  Future<void> _openGoogleMapsRoute() async {
    final dest = '${widget.place.lat},${widget.place.lng}';
    String url;

    if (_userPosition != null) {
      final origin = '${_userPosition!.latitude},${_userPosition!.longitude}';
      url = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving';
    } else {
      url = 'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving';
    }

    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // Fallback buka di browser
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );
    }
  }

  void _centerToPlace() {
    _mapController.move(
      LatLng(widget.place.lat, widget.place.lng),
      15.0,
    );
  }

  void _centerToUser() {
    if (_userPosition != null) {
      _mapController.move(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        15.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeLatLng = LatLng(widget.place.lat, widget.place.lng);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Cream beige background
      appBar: AppBar(
        title: Text(widget.place.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: const Color(0xFFF5F5DC),
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: Color(0xFF2D8B6F)),
            onPressed: _loadingLocation ? null : _centerToUser,
            tooltip: 'Lokasi saya',
          ),
          IconButton(
            icon: const Icon(Icons.place_rounded, color: Color(0xFFDC2626)),
            onPressed: _centerToPlace,
            tooltip: 'Lokasi tempat',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // ─── Peta ──────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: placeLatLng,
              initialZoom: 15.0,
            ),
            children: [
              // Tile layer OpenStreetMap
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_hotel',
              ),

              // Marker lokasi user
              if (_userPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                          _userPosition!.latitude, _userPosition!.longitude),
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))
                          ]
                        ),
                        child: const Icon(
                          Icons.person_pin_circle_rounded,
                          color: Color(0xFF2D8B6F), // Deep green
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                ),

              // Marker lokasi tempat
              MarkerLayer(
                markers: [
                  Marker(
                    point: placeLatLng,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFFDC2626), // Soft red
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ─── Info card tempat ──────────────────────
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E8E8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D8B6F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_city_rounded,
                        color: Color(0xFF2D8B6F), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.place.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A1A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.place.address,
                          style: const TextStyle(
                              color: Color(0xFF8899A6), fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Error lokasi ──────────────────────────
          if (_locationError != null)
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ─── Loading lokasi ────────────────────────
          if (_loadingLocation)
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Color(0xFF2D8B6F), strokeWidth: 2.5),
                    ),
                    SizedBox(width: 12),
                    Text('Mendapatkan lokasi kamu...',
                        style: TextStyle(fontSize: 13, color: Color(0xFF555555), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),

      // ─── Tombol Buka Rute ──────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGoogleMapsRoute,
        backgroundColor: const Color(0xFF2D8B6F),
        elevation: 0,
        icon: const Icon(Icons.directions_rounded, color: Colors.white, size: 22),
        label: const Text(
          'Buka Rute',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}