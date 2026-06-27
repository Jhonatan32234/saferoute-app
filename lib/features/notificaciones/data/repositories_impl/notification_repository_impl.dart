import 'package:injectable/injectable.dart';
import '../../domain/entities/notificacion_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

@LazySingleton(as: INotificacionRepository)
class NotificacionRepositoryImpl implements INotificacionRepository {
  final NotificacionRemoteDataSource _api;
  NotificacionRepositoryImpl(this._api);

  @override
  Future<List<NotificacionEntity>> getHistorial(String token) async {
    return await _api.getHistorial(token);
  }
}