import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../notificaciones/domain/entities/notificacion_entity.dart';
import '../../../notificaciones/presentation/providers/notificacion_provider.dart';
import '../../../reportes/presentation/providers/reporte_provider.dart';
import '../../../reportes/presentation/providers/reporte_state.dart';
import '../../../reportes/presentation/widgets/report_button_widget.dart';
import '../../../../core/utils/reporte_mapper.dart';
import '../providers/mapa_provider.dart';

class HomeReportPanel extends StatefulWidget {
  final Function(String) onReportSent;
  const HomeReportPanel({super.key, required this.onReportSent});

  @override
  State<HomeReportPanel> createState() => _HomeReportPanelState();
}

class _HomeReportPanelState extends State<HomeReportPanel> {
  @override
  Widget build(BuildContext context) {
    final reporteProvider = context.watch<ReporteProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ReportButtonWidget(
          onReporteEnviado: (tipo, notaVoz) async {
            await _enviarReporte(context, tipo, notaVoz);
          },
          isLoading: reporteProvider.enviando,
          errorMessage: reporteProvider.error,
        ),
      ],
    );
  }

  Future<void> _enviarReporte(BuildContext context, String tipo, String notaVoz) async {
    final reporteProvider = context.read<ReporteProvider>();
    final mapaProvider = context.read<MapaProvider>();
    final notiProvider = context.read<NotificacionProvider>();

    final lat = mapaProvider.ubicacionActual.latitude;
    final lon = mapaProvider.ubicacionActual.longitude;
    final rutaId = mapaProvider.rutaSeleccionada?.id ?? 'sin-ruta';

    await reporteProvider.enviarReporte(
      tipo: tipo,
      latitud: lat,
      longitud: lon,
      notaVoz: notaVoz,
      rutaId: rutaId,
    );

    // Si el estado es Error, lanzamos una excepción para que el widget no cambie a "Enviado"
    if (reporteProvider.state is ReporteError) {
      throw Exception(reporteProvider.error);
    }
      
    // Si fue exitoso (o guardado localmente), procedemos con la notificación
    final label = ReporteMapper.getLabel(tipo);
    widget.onReportSent(label);

    final reportId = DateTime.now().millisecondsSinceEpoch.toString();
    notiProvider.agregarAlertaLocal(
      NotificacionEntity(
        id: reportId,
        reporteId: reportId,
        mensaje: 'Reportaste: $label',
        tipo: tipo,
        latitud: lat,
        longitud: lon,
        timestamp: DateTime.now(),
        leida: true,
        esAdmin: false,
        notaVoz: notaVoz,
        rutaId: rutaId,
      ),
    );
  }
}
