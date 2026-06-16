import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaPage extends StatelessWidget {
  final double lat;
  final double lon;
  final List<Map<String, dynamic>> clusters;

  const MapaPage({
    super.key,
    required this.lat,
    required this.lon,
    this.clusters = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Riesgo')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(lat, lon),
          initialZoom: 8.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.jmj.saferoute',
          ),
          // Clusters de riesgo
          MarkerLayer(
            markers: clusters.map((c) {
              final riesgo = (c['riesgo_combinado'] ?? 0).toDouble();
              Color color;
              if (riesgo > 15) {
                color = Colors.red;
              } else if (riesgo > 5) {
                color = Colors.orange;
              } else if (riesgo > 0.5) {
                color = Colors.yellow;
              } else {
                color = Colors.green;
              }

              return Marker(
                point: LatLng(
                  (c['lat'] ?? 0).toDouble(),
                  (c['lon'] ?? 0).toDouble(),
                ),
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Center(
                    child: Text(
                      '${c['cluster_id'] ?? ''}',
                      style: const TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}