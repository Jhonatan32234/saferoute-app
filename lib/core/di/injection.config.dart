// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_dotenv/flutter_dotenv.dart' as _i170;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/home/data/datasources/home_remote_datasource.dart'
    as _i278;
import '../../features/home/data/repositories_impl/home_local_repository_impl.dart'
    as _i110;
import '../../features/home/data/repositories_impl/home_repository_impl.dart'
    as _i90;
import '../../features/home/data/repositories_impl/location_repository_impl.dart'
    as _i406;
import '../../features/home/domain/repositories/home_local_repository.dart'
    as _i925;
import '../../features/home/domain/repositories/home_repository.dart' as _i0;
import '../../features/home/domain/repositories/location_repository.dart'
    as _i853;
import '../../features/home/domain/usecases/buscar_rutas_use_case.dart'
    as _i364;
import '../../features/home/domain/usecases/destinos_recientes_use_cases.dart'
    as _i116;
import '../../features/home/domain/usecases/ubicacion_use_cases.dart' as _i559;
import '../../features/home/domain/usecases/viaje_use_cases.dart' as _i5;
import '../../features/home/presentation/providers/mapa_provider.dart'
    as _i1031;
import '../../features/login/data/datasources/login_remote_datasource.dart'
    as _i1033;
import '../../features/login/data/repositories_impl/auth_repository_impl.dart'
    as _i337;
import '../../features/login/domain/repositories/auth_repository.dart' as _i268;
import '../../features/login/domain/usecases/login_use_case.dart' as _i1005;
import '../../features/login/presentation/providers/auth_provider.dart'
    as _i787;
import '../../features/notificaciones/data/datasources/notification_remote_datasource.dart'
    as _i842;
import '../../features/notificaciones/data/repositories_impl/notification_repository_impl.dart'
    as _i464;
import '../../features/notificaciones/domain/repositories/notification_repository.dart'
    as _i931;
import '../../features/notificaciones/domain/usecases/detener_notificaciones_ruta_use_case.dart'
    as _i76;
import '../../features/notificaciones/domain/usecases/enviar_telemetria_use_case.dart'
    as _i89;
import '../../features/notificaciones/domain/usecases/marcar_notificacion_leida_use_case.dart'
    as _i98;
import '../../features/notificaciones/domain/usecases/marcar_todas_notificaciones_leidas_use_case.dart'
    as _i479;
import '../../features/notificaciones/domain/usecases/observar_notificaciones_ruta_use_case.dart'
    as _i607;
import '../../features/notificaciones/domain/usecases/obtener_historial_notificaciones_use_case.dart'
    as _i99;
import '../../features/notificaciones/presentation/providers/notificacion_provider.dart'
    as _i740;
import '../../features/profile/data/datasources/profile_remote_datasource.dart'
    as _i327;
import '../../features/profile/data/repositories_impl/profile_repository_impl.dart'
    as _i357;
import '../../features/profile/domain/repositories/profile_repository.dart'
    as _i894;
import '../../features/profile/domain/usecases/actualizar_perfil_use_case.dart'
    as _i965;
import '../../features/profile/domain/usecases/obtener_perfil_use_case.dart'
    as _i908;
import '../../features/profile/presentation/providers/profile_provider.dart'
    as _i919;
import '../../features/reportes/data/datasources/reportes_remote_datasource.dart'
    as _i804;
import '../../features/reportes/data/repositories_impl/reporte_pendiente_repository_impl.dart'
    as _i1019;
import '../../features/reportes/data/repositories_impl/reporte_repository_impl.dart'
    as _i240;
import '../../features/reportes/domain/repositories/reporte_pendiente_repository.dart'
    as _i378;
import '../../features/reportes/domain/repositories/reporte_repository.dart'
    as _i987;
import '../../features/reportes/domain/usecases/enviar_reporte_use_case.dart'
    as _i836;
import '../../features/reportes/domain/usecases/sincronizar_reportes_pendientes_use_case.dart'
    as _i232;
import '../../features/reportes/presentation/providers/reporte_provider.dart'
    as _i117;
import '../network/api_client.dart' as _i557;
import '../network/session_service.dart' as _i505;
import '../security/security_service.dart' as _i383;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i170.DotEnv>(
      () => registerModule.dotenvInstance,
      preResolve: true,
    );
    gh.lazySingleton<_i519.Client>(() => registerModule.httpClient);
    gh.lazySingleton<_i558.FlutterSecureStorage>(() => registerModule.storage);
    gh.lazySingleton<_i383.SecurityService>(() => _i383.SecurityService());
    gh.lazySingleton<_i925.IHomeLocalRepository>(
        () => _i110.HomeLocalRepositoryImpl(gh<_i558.FlutterSecureStorage>()));
    gh.lazySingleton<_i505.SessionService>(
        () => _i505.SessionService(gh<_i558.FlutterSecureStorage>()));
    gh.lazySingleton<_i378.IReportePendienteRepository>(() =>
        _i1019.ReportePendienteRepositoryImpl(
            gh<_i558.FlutterSecureStorage>()));
    gh.lazySingleton<_i853.ILocationRepository>(
        () => _i406.LocationRepositoryImpl());
    gh.lazySingleton<_i559.ObtenerUbicacionActualUseCase>(() =>
        _i559.ObtenerUbicacionActualUseCase(gh<_i853.ILocationRepository>()));
    gh.lazySingleton<_i559.ObservarUbicacionUseCase>(
        () => _i559.ObservarUbicacionUseCase(gh<_i853.ILocationRepository>()));
    gh.lazySingleton<_i557.ApiClient>(() => _i557.ApiClient(
          gh<_i519.Client>(),
          gh<_i505.SessionService>(),
        ));
    gh.lazySingleton<_i278.HomeRemoteDataSource>(
        () => _i278.HomeRemoteDataSource(
              gh<_i557.ApiClient>(),
              gh<_i170.DotEnv>(),
            ));
    gh.lazySingleton<_i1033.LoginRemoteDataSource>(
        () => _i1033.LoginRemoteDataSource(
              gh<_i557.ApiClient>(),
              gh<_i170.DotEnv>(),
            ));
    gh.lazySingleton<_i327.ProfileRemoteDataSource>(
        () => _i327.ProfileRemoteDataSource(
              gh<_i557.ApiClient>(),
              gh<_i170.DotEnv>(),
            ));
    gh.lazySingleton<_i804.ReportesRemoteDataSource>(
        () => _i804.ReportesRemoteDataSource(
              gh<_i557.ApiClient>(),
              gh<_i170.DotEnv>(),
            ));
    gh.lazySingleton<_i894.IProfileRepository>(
        () => _i357.ProfileRepositoryImpl(gh<_i327.ProfileRemoteDataSource>()));
    gh.lazySingleton<_i987.IReporteRepository>(() =>
        _i240.ReporteRepositoryImpl(gh<_i804.ReportesRemoteDataSource>()));
    gh.lazySingleton<_i842.NotificacionRemoteDataSource>(
        () => _i842.NotificacionRemoteDataSource(
              gh<_i557.ApiClient>(),
              gh<_i170.DotEnv>(),
              gh<_i505.SessionService>(),
            ));
    gh.lazySingleton<_i268.IAuthRepository>(() => _i337.AuthRepositoryImpl(
          gh<_i1033.LoginRemoteDataSource>(),
          gh<_i558.FlutterSecureStorage>(),
        ));
    gh.lazySingleton<_i919.ProfileProvider>(
        () => _i919.ProfileProvider(gh<_i894.IProfileRepository>()));
    gh.lazySingleton<_i965.ActualizarPerfilUseCase>(
        () => _i965.ActualizarPerfilUseCase(gh<_i894.IProfileRepository>()));
    gh.lazySingleton<_i908.ObtenerPerfilUseCase>(
        () => _i908.ObtenerPerfilUseCase(gh<_i894.IProfileRepository>()));
    gh.lazySingleton<_i931.INotificacionRepository>(() =>
        _i464.NotificacionRepositoryImpl(
            gh<_i842.NotificacionRemoteDataSource>()));
    gh.lazySingleton<_i1005.LoginUseCase>(
        () => _i1005.LoginUseCase(gh<_i268.IAuthRepository>()));
    gh.lazySingleton<_i76.DetenerNotificacionesRutaUseCase>(() =>
        _i76.DetenerNotificacionesRutaUseCase(
            gh<_i931.INotificacionRepository>()));
    gh.lazySingleton<_i89.EnviarTelemetriaUseCase>(() =>
        _i89.EnviarTelemetriaUseCase(gh<_i931.INotificacionRepository>()));
    gh.lazySingleton<_i98.MarcarNotificacionLeidaUseCase>(() =>
        _i98.MarcarNotificacionLeidaUseCase(
            gh<_i931.INotificacionRepository>()));
    gh.lazySingleton<_i479.MarcarTodasNotificacionesLeidasUseCase>(() =>
        _i479.MarcarTodasNotificacionesLeidasUseCase(
            gh<_i931.INotificacionRepository>()));
    gh.lazySingleton<_i607.ObservarNotificacionesRutaUseCase>(() =>
        _i607.ObservarNotificacionesRutaUseCase(
            gh<_i931.INotificacionRepository>()));
    gh.lazySingleton<_i99.ObtenerHistorialNotificacionesUseCase>(() =>
        _i99.ObtenerHistorialNotificacionesUseCase(
            gh<_i931.INotificacionRepository>()));
    gh.lazySingleton<_i836.EnviarReporteUseCase>(
        () => _i836.EnviarReporteUseCase(
              gh<_i987.IReporteRepository>(),
              gh<_i378.IReportePendienteRepository>(),
            ));
    gh.lazySingleton<_i232.SincronizarReportesPendientesUseCase>(
        () => _i232.SincronizarReportesPendientesUseCase(
              gh<_i987.IReporteRepository>(),
              gh<_i378.IReportePendienteRepository>(),
            ));
    gh.lazySingleton<_i740.NotificacionProvider>(() => _i740.NotificacionProvider(
          gh<_i931.INotificacionRepository>(),
          gh<_i505.SessionService>(),
        ));
    gh.lazySingleton<_i117.ReporteProvider>(() => _i117.ReporteProvider(
          gh<_i987.IReporteRepository>(),
          gh<_i558.FlutterSecureStorage>(),
        ));
    gh.lazySingleton<_i0.IHomeRepository>(
        () => _i90.HomeRepositoryImpl(gh<_i278.HomeRemoteDataSource>()));
    gh.lazySingleton<_i364.BuscarRutasUseCase>(
        () => _i364.BuscarRutasUseCase(gh<_i0.IHomeRepository>()));
    gh.lazySingleton<_i116.ObtenerDestinosRecientesUseCase>(
        () => _i116.ObtenerDestinosRecientesUseCase(gh<_i0.IHomeRepository>()));
    gh.lazySingleton<_i116.EliminarDestinoRecienteUseCase>(
        () => _i116.EliminarDestinoRecienteUseCase(gh<_i0.IHomeRepository>()));
    gh.lazySingleton<_i787.AuthProvider>(() => _i787.AuthProvider(
          gh<_i268.IAuthRepository>(),
          gh<_i505.SessionService>(),
          gh<_i1005.LoginUseCase>(),
        ));
    gh.lazySingleton<_i5.IniciarViajeUseCase>(() => _i5.IniciarViajeUseCase(
          gh<_i0.IHomeRepository>(),
          gh<_i925.IHomeLocalRepository>(),
        ));
    gh.lazySingleton<_i5.FinalizarViajeUseCase>(() => _i5.FinalizarViajeUseCase(
          gh<_i0.IHomeRepository>(),
          gh<_i925.IHomeLocalRepository>(),
        ));
    gh.lazySingleton<_i1031.MapaProvider>(() => _i1031.MapaProvider(
          gh<_i0.IHomeRepository>(),
          gh<_i170.DotEnv>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
