import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../reportes/presentation/providers/reporte_provider.dart';
import '../../../reportes/presentation/widgets/report_button_widget.dart';
import '../providers/mapa_provider.dart';

class HomeReportPanel extends StatelessWidget {
  const HomeReportPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final reporteProvider = context.watch<ReporteProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (reporteProvider.ultimoResultado != null)
          _StatusMessage(
            message: reporteProvider.ultimoResultado == 'éxito' 
                ? 'Reporte enviado' 
                : reporteProvider.error ?? 'Error',
            isSuccess: reporteProvider.ultimoResultado == 'éxito',
          ),
        if (reporteProvider.enviando)
          const _LoadingIndicator(),
        ReportButtonWidget(
          onReporteEnviado: (tipo, notaVoz) => _enviarReporte(context, tipo, notaVoz),
          isLoading: reporteProvider.enviando,
        ),
      ],
    );
  }

  void _enviarReporte(BuildContext context, String tipo, String notaVoz) {
    final reporteProvider = context.read<ReporteProvider>();
    final mapaProvider = context.read<MapaProvider>();

    final rutaId = mapaProvider.rutaSeleccionada?.id ?? 'sin-ruta';

    reporteProvider.enviarReporte(
      tipo: tipo,
      latitud: mapaProvider.ubicacionActual.latitude,
      longitud: mapaProvider.ubicacionActual.longitude,
      notaVoz: notaVoz,
      rutaId: rutaId,
    );
  }
}

class _StatusMessage extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const _StatusMessage({
    required this.message,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSuccess ? Colors.green : theme.colorScheme.error;
    final bgColor = isSuccess ? Colors.green.withOpacity(0.1) : theme.colorScheme.error.withOpacity(0.1);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: color,
            size: 20.r,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.r,
            height: 20.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.surface,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Enviando reporte...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.surface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
