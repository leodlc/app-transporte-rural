import 'package:geolocator/geolocator.dart';

class GeolocatorHelper {
  static Future<double> calcularDistancia(
      double lat1,
      double lng1,
      double lat2,
      double lng2,
      ) async {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }
}
