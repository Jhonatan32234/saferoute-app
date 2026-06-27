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
import '../../features/home/data/repositories_impl/home_repository_impl.dart'
    as _i90;
import '../../features/home/domain/repositories/home_repository.dart' as _i0;
import '../../features/home/presentation/providers/mapa_provider.dart'
    as _i1031;
import '../../features/login/data/datasources/login_remote_datasource.dart'
    as _i1033;
import '../../features/login/data/repositories_impl/auth_repository_impl.dart'
    as _i337;
import '../../features/login/domain/repositories/auth_repository.dart' as _i268;
import '../../features/login/presentation/providers/auth_provider.dart'
    as _i787;
import '../../features/notificaciones/data/datasources/notification_remote_datasource.dart'
    as _i842;
import '../../features/notificaciones/data/repositories_impl/notification_repository_impl.dart'
    as _i464;
import '../../features/notificaciones/domain/repositories/notification_repository.dart'
    as _i931;
import '../../features/notificaciones/presentation/providers/notificacion_provider.dart'
    as _i740;
import '../../features/reportes/data/datasources/reportes_remote_datasource.dart'
    as _i804;
import '../../features/reportes/data/repositories_impl/reporte_repository_impl.dart'
    as _i240;
import '../../features/reportes/domain/repositories/reporte_repository.dart'
    as _i987;
import '../../features/reportes/presentation/providers/reporte_provider.dart'
    as _i117;
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
    gh.lazySingleton<_i278.HomeRemoteDataSource>(
        () => _i278.HomeRemoteDataSource(
              gh<_i519.Client>(),
              gh<_i170.DotEnv>(),
            ));
    gh.lazySingleton<_i1033.LoginRemoteDataSource>(
        () => _i1033.LoginRemoteDataSource(
              gh<_i519.Client>(),
              gh<_i170.DotEnv>(),
            ));
    gh.lazySingleton<_i842.NotificacionRemoteDataSource>(
        () => _i842.NotificacionRemoteDataSource(
              gh<_i519.Client>(),
              gh<_i170.DotEnv>(),
            ));
    gh.lazySingleton<_i804.ReportesRemoteDataSource>(
        () => _i804.ReportesRemoteDataSource(
              gh<_i519.Client>(),
              gh<_i170.DotEnv>(),
            ));
    gh.lazySingleton<_i987.IReporteRepository>(() =>
        _i240.ReporteRepositoryImpl(gh<_i804.ReportesRemoteDataSource>()));
    gh.lazySingleton<_i268.IAuthRepository>(() => _i337.AuthRepositoryImpl(
          gh<_i1033.LoginRemoteDataSource>(),
          gh<_i558.FlutterSecureStorage>(),
        ));
    gh.factory<_i787.AuthProvider>(
        () => _i787.AuthProvider(gh<_i268.IAuthRepository>()));
    gh.lazySingleton<_i931.INotificacionRepository>(() =>
        _i464.NotificacionRepositoryImpl(
            gh<_i842.NotificacionRemoteDataSource>()));
    gh.factory<_i740.NotificacionProvider>(
        () => _i740.NotificacionProvider(gh<_i842.NotificacionRemoteDataSource>()));
    gh.factory<_i117.ReporteProvider>(() => _i117.ReporteProvider(
          gh<_i987.IReporteRepository>(),
          gh<_i558.FlutterSecureStorage>(),
        ));
    gh.lazySingleton<_i0.IHomeRepository>(
        () => _i90.HomeRepositoryImpl(gh<_i278.HomeRemoteDataSource>()));
    gh.factory<_i1031.MapaProvider>(
        () => _i1031.MapaProvider(gh<_i0.IHomeRepository>()));
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
