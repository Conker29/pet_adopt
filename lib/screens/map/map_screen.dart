import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng _currentLocation = LatLng(-0.1807, -78.4678); // Quito default
  List<Marker> _markers = [];
  bool _isLoading = true;
  String? _error;
  final MapController _mapController = MapController();
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadShelters();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Permisos de ubicación denegados';
            _locationPermissionGranted = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Permisos de ubicación denegados permanentemente';
          _locationPermissionGranted = false;
        });
        return;
      }

      // Obtener ubicación actual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _locationPermissionGranted = true;
      });

      // Mover el mapa a la ubicación actual
      _mapController.move(_currentLocation, 13);
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _error = 'No se pudo obtener la ubicación';
        _locationPermissionGranted = false;
      });
    }
  }

  Future<void> _loadShelters() async {
    try {
      final response = await Supabase.instance.client
          .from('shelters')
          .select('id, name, latitude, longitude');

      final markers = <Marker>[];

      // Agregar marcador de ubicación actual
      if (_locationPermissionGranted) {
        markers.add(
          Marker(
            point: _currentLocation,
            width: 50,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 30,
              ),
            ),
          ),
        );
      }

      // Agregar marcadores de refugios
      for (var shelter in response as List) {
        markers.add(
          Marker(
            point: LatLng(
              double.parse(shelter['latitude'].toString()),
              double.parse(shelter['longitude'].toString()),
            ),
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () => _showShelterInfo(shelter),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      setState(() {
        _markers = markers;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar refugios: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showShelterInfo(Map<String, dynamic> shelter) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.home, color: Colors.teal, size: 30),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shelter['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Refugio de animales',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildInfoRow(
              Icons.location_on,
              'Ubicación',
              '${shelter['latitude']}, ${shelter['longitude']}',
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _mapController.move(
                        LatLng(
                          double.parse(shelter['latitude'].toString()),
                          double.parse(shelter['longitude'].toString()),
                        ),
                        15,
                      );
                    },
                    icon: Icon(Icons.center_focus_strong),
                    label: Text('Centrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    label: Text('Cerrar'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            SizedBox(height: 16),
            Text('Cargando mapa...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
              SizedBox(height: 16),
              Text(
                'Error al cargar el mapa',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initializeMap();
                },
                icon: Icon(Icons.refresh),
                label: Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation,
            initialZoom: 13,
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.pet_adopt',
            ),
            MarkerLayer(markers: _markers),
          ],
        ),

        // Botón de ubicación actual
        if (_locationPermissionGranted)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                _mapController.move(_currentLocation, 15);
              },
              child: Icon(Icons.my_location),
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              mini: true,
            ),
          ),

        // Leyenda
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home, color: Colors.teal, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Refugios cercanos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  Text(
                    '${_markers.length - (_locationPermissionGranted ? 1 : 0)} refugios',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}