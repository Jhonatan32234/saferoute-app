import 'package:latlong2/latlong.dart';
import '../../domain/entities/ruta_entity.dart';
import '../../domain/entities/destino_reciente_entity.dart';

sealed class MapaState {
  const MapaState();
}

class MapaInitial extends MapaState {
  const MapaInitial();
}

class MapaLoading extends MapaState {
  const MapaLoading();
}

class MapaRoutesLoaded extends MapaState {
  final List<RutaEntity> rutas;
  final List<List<LatLng>> polilineas;
  final int? selectedIndex;
  const MapaRoutesLoaded({
    required this.rutas, 
    required this.polilineas,
    this.selectedIndex,
  });

  MapaRoutesLoaded copyWith({int? selectedIndex}) {
    return MapaRoutesLoaded(
      rutas: rutas,
      polilineas: polilineas,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

class MapaInTrip extends MapaState {
  final RutaEntity ruta;
  final String viajeId;
  final bool desviado;
  const MapaInTrip({required this.ruta, required this.viajeId, this.desviado = false});
}

class MapaError extends MapaState {
  final String message;
  const MapaError(this.message);
}
