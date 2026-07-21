import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../reportes/presentation/providers/reporte_provider.dart';
import '../../../reportes/presentation/widgets/report_button_widget.dart';

class HomeReportPanel extends StatelessWidget {
  const HomeReportPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final reporteProvider = context.watch<ReporteProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Aquí podrías añadir un mensaje de éxito temporal si quieres
        ReportButtonWidget(
          onReporteEnviado: (tipo, notaVoz) {
            // Lógica de envío ya configurada
          },
          isLoading: reporteProvider.enviando,
        ),
      ],
    );
  }
}
