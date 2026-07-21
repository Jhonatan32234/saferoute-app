import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/utils/reporte_mapper.dart';

class ReportButtonWidget extends StatefulWidget {
  final Function(String tipo, String notaVoz) onReporteEnviado;
  final bool isLoading;

  const ReportButtonWidget({super.key, required this.onReporteEnviado, this.isLoading = false});

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
    return GestureDetector(
      onTap: () => setState(() => _state = ReportState.selecting),
      child: Container(
        width: double.infinity, height: 56.h,
        decoration: BoxDecoration(color: const Color(0xFFC93F33), borderRadius: BorderRadius.circular(16.r)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 12.w),
            Text('Reportar incidente', style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿QUÉ OCURRIÓ?', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.2)),
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
                    _words = ''; // Limpiar palabras anteriores
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
    final color = Color(int.parse(_selectedType!['color'].replaceFirst('#', '0xFF')));
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24.r)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_selectedType!['icon'] as IconData, color: color, size: 22.r),
              SizedBox(width: 10.w),
              Text(_selectedType!['label'], style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.black)),
            ],
          ),
          
          // FEEDBACK DE VOZ (Texto dinámico mientras grabas)
          if (_recording || _words.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _words.isEmpty ? "Escuchando..." : _words,
                style: TextStyle(
                  fontSize: 14.sp, 
                  color: _words.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                  fontStyle: _words.isEmpty ? FontStyle.italic : FontStyle.normal,
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
              onPressed: _recording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _recording ? const Color(0xFF2563EB) : const Color(0xFF4A90C2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_recording ? Icons.stop : Icons.mic, size: 20, color: Colors.white),
                  SizedBox(width: 10.w),
                  Text(
                    _recording ? 'Grabar y enviar' : 'Toca para grabar', 
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.white)
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
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24.r)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_selectedType!['icon'] as IconData, color: Colors.black45, size: 22.r),
              SizedBox(width: 10.w),
              Text(_selectedType!['label'], style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: Colors.black45)),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity, height: 54.h,
            decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(14.r)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check, color: Colors.white),
                SizedBox(width: 10.w),
                const Text('Reporte enviado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          side: const BorderSide(color: Color(0xFFF1F5F9)),
          backgroundColor: const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
        child: Text('Cancelar', style: TextStyle(color: const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 14.sp)),
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
    setState(() { _recording = false; _state = ReportState.sent; });
    
    final label = _selectedType!['label'];
    widget.onReporteEnviado(_selectedType!['tipo'], _words.isEmpty ? "Reporte de $label" : _words);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _state = ReportState.idle);
    });
  }
}

enum ReportState { idle, selecting, recording, sent }
