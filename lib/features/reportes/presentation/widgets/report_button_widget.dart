import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/utils/reporte_mapper.dart';

class ReportButtonWidget extends StatefulWidget {
  final Future<void> Function(String tipo, String notaVoz) onReporteEnviado;
  final bool isLoading;
  final String? errorMessage;

  const ReportButtonWidget({
    super.key, 
    required this.onReporteEnviado, 
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<ReportButtonWidget> createState() => _ReportButtonWidgetState();
}

class _ReportButtonWidgetState extends State<ReportButtonWidget> {
  ReportState _state = ReportState.idle;
  Map<String, dynamic>? _selectedType;
  bool _recording = false;
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _words = '';

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildPanel(),
    );
  }

  Widget _buildPanel() {
    switch (_state) {
      case ReportState.idle:
        return _buildIdleButton();
      case ReportState.selecting:
        return _buildTypeSelector();
      case ReportState.recording:
        return _buildRecordingPanel();
      case ReportState.sent:
        return _buildSentPanel();
    }
  }

  Widget _buildIdleButton() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _state = ReportState.selecting),
      child: Container(
        width: double.infinity, height: 56.h,
        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(16.r)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onError),
            SizedBox(width: 12.w),
            Text('Reportar incidente', style: TextStyle(color: theme.colorScheme.onError, fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿QUÉ OCURRIÓ?', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 1.2)),
          SizedBox(height: 16.h),
          SizedBox(
            height: 85.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ReporteMapper.tiposUI.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (context, i) {
                final item = ReporteMapper.tiposUI[i];
                final color = Color(int.parse(item['color'].replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () => setState(() { 
                    _selectedType = item; 
                    _state = ReportState.recording; 
                    _words = '';
                  }),
                  child: Column(
                    children: [
                      Container(
                        width: 50.r, height: 50.r,
                        decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                        child: Icon(item['icon'] as IconData, color: color, size: 24.r),
                      ),
                      SizedBox(height: 8.h),
                      Text(item['label'], style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20.h),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildRecordingPanel() {
    final theme = Theme.of(context);
    final color = Color(int.parse(_selectedType!['color'].replaceFirst('#', '0xFF')));
    final hasError = widget.errorMessage != null;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24.r)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_selectedType!['icon'] as IconData, color: color, size: 22.r),
              SizedBox(width: 10.w),
              Text(_selectedType!['label'], style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          
          if (hasError) ...[
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) => Opacity(opacity: value, child: child),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 14.h, bottom: 6.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  widget.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],

          if (_recording || _words.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _words.isEmpty ? "Escuchando..." : _words,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _words.isEmpty ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity, height: 54.h,
            child: ElevatedButton(
              onPressed: (widget.isLoading) ? null : (_recording ? _stopRecording : _startRecording),
              style: ElevatedButton.styleFrom(
                backgroundColor: _recording ? theme.colorScheme.error : theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                elevation: 0,
              ),
              child: widget.isLoading 
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: theme.colorScheme.onError, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_recording ? Icons.stop : Icons.mic, size: 20),
                      SizedBox(width: 10.w),
                      Text(
                        _recording ? 'Enviar ahora' : 'Toca para grabar', 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
            ),
          ),
          SizedBox(height: 12.h),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildSentPanel() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24.r)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_selectedType!['icon'] as IconData, color: theme.disabledColor, size: 22.r),
              SizedBox(width: 10.w),
              Text(_selectedType!['label'], style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.disabledColor)),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity, height: 54.h,
            decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(14.r)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, color: theme.colorScheme.onSecondary),
                SizedBox(width: 10.w),
                Text('Reporte enviado', style: TextStyle(color: theme.colorScheme.onSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          _buildCancelButton(),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity, height: 50.h,
      child: OutlinedButton(
        onPressed: () {
          _speech.stop();
          setState(() {
            _state = ReportState.idle;
            _recording = false;
            _words = '';
          });
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
        child: Text('Cancelar', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _startRecording() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() { _recording = true; _words = ''; });
      _speech.listen(
        onResult: (val) {
          if (mounted) setState(() => _words = val.recognizedWords);
        },
        localeId: 'es_MX',
      );
    }
  }

  void _stopRecording() async {
    await _speech.stop();
    setState(() { _recording = false; });
    
    final label = _selectedType!['label'];
    final notaVoz = _words.isEmpty ? "Reporte de $label" : _words;

    try {
      await widget.onReporteEnviado(_selectedType!['tipo'], notaVoz);
      if (mounted) {
        setState(() { 
          _state = ReportState.sent; 
          _words = '';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _state = ReportState.idle);
        });
      }
    } catch (e) {
      // El error ya lo maneja el Provider
    }
  }
}

enum ReportState { idle, selecting, recording, sent }
