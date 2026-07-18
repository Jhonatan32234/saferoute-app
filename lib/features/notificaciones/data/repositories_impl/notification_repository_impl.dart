import 'package:injectable/injectable.dart';
import '../../domain/entities/notificacion_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

@LazySingleton(as: INotificacionRepository)
class NotificacionRepositoryImpl implements INotificacionRepository {
  final NotificacionRemoteDataSource _api;
  NotificacionRepositoryImpl(this._api);

  @override
  Future<List<NotificacionEntity>> getHistorial() async {
    final historial = await _api.getHistorial();
    return historial.map((item) => item.toEntity()).toList();
  }

  @override
  Future<void> marcarLeida(String id) async {
    await _api.marcarLeida(id);
  }

  @override
  Future<void> marcarTodasLeidas() async {
    await _api.marcarTodasLeidas();
  }

  @override
  String get baseUrl => _api.baseUrl;
}
