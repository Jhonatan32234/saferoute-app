enum DisposicionEnvioReporte { enviado, encolado }

class ResultadoEnvioReporte {
  final DisposicionEnvioReporte disposicion;

  const ResultadoEnvioReporte(this.disposicion);

  bool get fueEncolado => disposicion == DisposicionEnvioReporte.encolado;
}

class ResultadoSincronizacionReportes {
  final int enviados;
  final int pendientes;

  const ResultadoSincronizacionReportes({
    required this.enviados,
    required this.pendientes,
  });
}
