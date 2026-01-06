import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Cache de la última ubicación conocida
  Position? _lastKnownPosition;
  
  /// Verifica si los servicios de ubicación están habilitados
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Verifica el estado de los permisos de ubicación
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Solicita permisos de ubicación
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Verifica y solicita permisos si es necesario
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Obtiene la ubicación actual del dispositivo
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return _lastKnownPosition;
    }
  }

  /// Obtiene la ubicación actual como LatLng
  Future<LatLng?> getCurrentLatLng() async {
    final position = await getCurrentLocation();
    if (position == null) return null;
    
    return LatLng(position.latitude, position.longitude);
  }

  /// Calcula la distancia entre dos puntos en metros
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calcula la distancia entre dos LatLng en metros
  double calculateDistanceLatLng(LatLng start, LatLng end) {
    return calculateDistance(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  /// Formatea la distancia en un formato legible
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Obtiene un stream de actualizaciones de ubicación
  Stream<Position> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    final locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Abre la configuración de ubicación del dispositivo
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Abre la configuración de permisos de la app
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Obtiene la última ubicación conocida (más rápido pero puede ser antigua)
  Future<Position?> getLastKnownPosition() async {
    try {
      final hasPermission = await handleLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  /// Verifica si hay una ubicación en cache
  Position? get cachedPosition => _lastKnownPosition;

  /// Limpia la cache de ubicación
  void clearCache() {
    _lastKnownPosition = null;
  }
}