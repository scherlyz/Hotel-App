import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../models/place.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  final Place place;
  const MapScreen({super.key, required this.place});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const String _orsApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImMwNjM2ZmE1OTM5ZTQyZDc5MDRiOGYzM2E3OThkMDg1IiwiaCI6Im11cm11cjY0In0=';

  final MapController _mapController = MapController();
  double? _userLat;
  double? _userLng;
  List<LatLng> _routePoints = [];
  bool _loadingLocation = true;
  bool _loadingRoute = false;
  String? _locationError;
  String? _routeError;
  double? _distanceKm;
  int? _durationMin;

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
      final result = await getLocation(); 
      if (result != null) {
        setState(() {
          _userLat = result['lat'];
          _userLng = result['lng'];
          _loadingLocation = false;
        });
        await _fetchRoute();
      } else {
        setState(() {
          _locationError = 'Izin lokasi ditolak atau GPS tidak aktif.';
          _loadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Gagal mendapatkan lokasi: $e';
        _loadingLocation = false;
      });
    }
  }

  Future<void> _fetchRoute() async {
    if (_userLat == null || _userLng == null) return;
    setState(() {
      _loadingRoute = true;
      _routeError = null;
      _routePoints = [];
    });

    try {
      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car'
        '?api_key=$_orsApiKey'
        '&start=$_userLng,$_userLat'
        '&end=${widget.place.lng},${widget.place.lat}',
      );

      final response =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final feature = data['features'][0];
        final coords = feature['geometry']['coordinates'] as List;
        final summary = feature['properties']['summary'];

        final points = coords
            .map<LatLng>((c) => LatLng(
                (c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();

        setState(() {
          _routePoints = points;
          _distanceKm =
              (summary['distance'] as num).toDouble() / 1000;
          _durationMin =
              ((summary['duration'] as num).toDouble() / 60).round();
          _loadingRoute = false;
        });
        _fitBounds();
      } else {
        setState(() {
          _routeError = 'Gagal memuat rute (${response.statusCode})';
          _loadingRoute = false;
        });
      }
    } catch (e) {
      setState(() {
        _routeError = 'Gagal memuat rute: $e';
        _loadingRoute = false;
      });
    }
  }

  void _fitBounds() {
    if (_routePoints.isEmpty) return;
    final lats = _routePoints.map((p) => p.latitude);
    final lngs = _routePoints.map((p) => p.longitude);
    final bounds = LatLngBounds(
      LatLng(lats.reduce((a, b) => a < b ? a : b),
          lngs.reduce((a, b) => a < b ? a : b)),
      LatLng(lats.reduce((a, b) => a > b ? a : b),
          lngs.reduce((a, b) => a > b ? a : b)),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
            bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    });
  }

  Future<void> _openGoogleMapsRoute() async {
    final dest = '${widget.place.lat},${widget.place.lng}';
    String url;
    if (_userLat != null && _userLng != null) {
      url =
          'https://www.google.com/maps/dir/?api=1&origin=$_userLat,$_userLng&destination=$dest&travelmode=driving';
    } else {
      url =
          'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving';
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _centerToPlace() =>
      _mapController.move(LatLng(widget.place.lat, widget.place.lng), 15.0);

  void _centerToUser() {
    if (_userLat != null && _userLng != null) {
      _mapController.move(LatLng(_userLat!, _userLng!), 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeLatLng = LatLng(widget.place.lat, widget.place.lng);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: Text(widget.place.name,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: const Color(0xFFF5F5DC),
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded,
                color: Color(0xFF2D8B6F)),
            onPressed: _loadingLocation ? null : _centerToUser,
          ),
          IconButton(
            icon: const Icon(Icons.place_rounded, color: Color(0xFFDC2626)),
            onPressed: _centerToPlace,
          ),
          if (_userLat != null)
            IconButton(
              icon: const Icon(Icons.route_rounded,
                  color: Color(0xFF1565C0)),
              onPressed: _loadingRoute ? null : _fetchRoute,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: placeLatLng,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_hotel',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF1565C0),
                    ),
                  ],
                ),
              if (_userLat != null && _userLng != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_userLat!, _userLng!),
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: const Icon(
                            Icons.person_pin_circle_rounded,
                            color: Color(0xFF2D8B6F),
                            size: 36),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: placeLatLng,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_pin,
                        color: Color(0xFFDC2626), size: 50),
                  ),
                ],
              ),
            ],
          ),

          // Info card
          Positioned(
            bottom: 90,
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
                      offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D8B6F)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.location_city_rounded,
                            color: Color(0xFF2D8B6F), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.place.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Color(0xFF1A1A1A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(widget.place.address,
                                style: const TextStyle(
                                    color: Color(0xFF8899A6),
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_distanceKm != null && _durationMin != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _infoChip(Icons.straighten_rounded,
                            '${_distanceKm!.toStringAsFixed(1)} km',
                            'Jarak', const Color(0xFF1565C0)),
                        Container(
                            width: 1,
                            height: 36,
                            color: const Color(0xFFE8E8E8)),
                        _infoChip(Icons.access_time_rounded,
                            '$_durationMin menit',
                            'Estimasi', const Color(0xFF2D8B6F)),
                      ],
                    ),
                  ],
                  if (_loadingRoute) ...[
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Color(0xFF1565C0), strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Menghitung rute...',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ],
                  if (_routeError != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(_routeError!,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDC2626)))),
                        TextButton(
                            onPressed: _fetchRoute,
                            child: const Text('Coba lagi',
                                style: TextStyle(fontSize: 12))),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Error GPS
          if (_locationError != null)
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_locationError!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            ),

          // Loading GPS
          if (_loadingLocation)
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8E8E8)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Color(0xFF2D8B6F), strokeWidth: 2.5)),
                    SizedBox(width: 12),
                    Text('Mendapatkan lokasi kamu...',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF555555),
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGoogleMapsRoute,
        backgroundColor: const Color(0xFF2D8B6F),
        elevation: 0,
        icon: const Icon(Icons.directions_rounded,
            color: Colors.white, size: 22),
        label: const Text('Buka di Google Maps',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _infoChip(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: color)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}