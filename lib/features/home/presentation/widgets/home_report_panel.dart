import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../notificaciones/domain/entities/notificacion_entity.dart';
import '../../../notificaciones/presentation/providers/notificacion_provider.dart';
import '../../../reportes/presentation/providers/reporte_provider.dart';
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
          onReporteEnviado: (tipo, notaVoz) => _enviarReporte(context, tipo, notaVoz),
          isLoading: reporteProvider.enviando,
        ),
      ],
    );
  }

  void _enviarReporte(BuildContext context, String tipo, String notaVoz) async {
    final reporteProvider = context.read<ReporteProvider>();
    final mapaProvider = context.read<MapaProvider>();
    final notiProvider = context.read<NotificacionProvider>();

    final lat = mapaProvider.ubicacionActual.latitude;
    final lon = mapaProvider.ubicacionActual.longitude;
    final rutaId = mapaProvider.rutaSeleccionada?.id ?? 'sin-ruta';

    // Disparar la notificación superior con el label real
    final label = ReporteMapper.getLabel(tipo);
    widget.onReportSent(label);

    await reporteProvider.enviarReporte(
      tipo: tipo,
      latitud: lat,
      longitud: lon,
      notaVoz: notaVoz,
      rutaId: rutaId,
    );
      
    final reportId = DateTime.now().millisecondsSinceEpoch.toString();
    notiProvider.agregarAlertaLocal(
      NotificacionEntity(
        id: reportId,
        reporteId: reportId,
        mensaje: 'Reportaste: $label', // ✅ Ahora en español
        tipo: tipo, // Guardamos el ID técnico
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
