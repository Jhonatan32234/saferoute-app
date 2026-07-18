import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/reporte_mapper.dart';

class ReportButtonWidget extends StatefulWidget {
  final Function(String tipo, String notaVoz) onReporteEnviado;
  final bool isLoading;

  const ReportButtonWidget({
    super.key,
    required this.onReporteEnviado,
    this.isLoading = false,
  });

  @override
  State<ReportButtonWidget> createState() => _ReportButtonWidgetState();
}

class _ReportButtonWidgetState extends State<ReportButtonWidget>
    with SingleTickerProviderStateMixin {
  ReportState _state = ReportState.idle;
  String? _selectedType;
  bool _recording = false;
  int _timer = 0;
  late AnimationController _pulseController;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  String _words = '';

  final List<Map<String, dynamic>> incidentTypes = ReporteMapper.tiposUI;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) => debugPrint('🎤 STT Status: $status'),
        onError: (error) => debugPrint('🎤 STT Error: $error'),
      );
    } catch (e) {
      debugPrint('🎤 STT Init Error: $e');
      _speechEnabled = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppColors.danger;
    }
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'car_crash': return Icons.car_crash;
      case 'water_drop': return Icons.water_drop;
      case 'circle': return Icons.circle;
      case 'block': return Icons.block;
      case 'landslide': return Icons.landslide;
      case 'foggy': return Icons.foggy;
      case 'lightbulb_outline': return Icons.lightbulb_outline;
      default: return Icons.warning_amber_rounded;
    }
  }

  void _startRecording() async {
    if (!_speechEnabled) {
      await _initSpeech();
    }

    setState(() {
      _recording = true;
      _timer = 0;
      _words = '';
    });

    if (_speechEnabled) {
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _words = result.recognizedWords;
            });
          }
        },
        localeId: 'es_MX',
      );
    }

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_recording || !mounted) return false;
      setState(() => _timer++);
      return true;
    });
  }

  void _stopRecording() async {
    if (!_recording) return;
    
    await _speech.stop();
    setState(() => _recording = false);

    if (_timer >= 1 && _selectedType != null) {
      final tipoBackend = ReporteMapper.uiToBackend(_selectedType!);
      final notaParaEnviar = _words.trim().isNotEmpty 
          ? _words.trim() 
          : 'Reporte de ${_selectedType!.toLowerCase()}';

      widget.onReporteEnviado(tipoBackend, notaParaEnviar);
      
      setState(() => _state = ReportState.sent);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _state = ReportState.idle;
            _selectedType = null;
            _timer = 0;
          });
        }
      });
    } else {
      setState(() => _state = ReportState.selecting);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _buildCurrentState(),
    );
  }

  Widget _buildCurrentState() {
    switch (_state) {
      case ReportState.idle:
        return _buildIdleButton();
      case ReportState.selecting:
        return _buildTypeSelector();
      case ReportState.recording:
        return _buildRecordingButton();
      case ReportState.sent:
        return _buildSentConfirmation();
    }
  }

  Widget _buildIdleButton() {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _state = ReportState.selecting),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onError, size: 20.r),
            SizedBox(width: 8.w),
            Text(
              'Reportar incidente',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 24.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            child: Text(
              'SELECCIONA EL TIPO',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: theme.hintColor,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 80.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: incidentTypes.length,
              separatorBuilder: (_, __) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final type = incidentTypes[index];
                final color = _getColorFromHex(type['color'] as String);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = type['tipo'];
                      _state = ReportState.recording;
                    });
                  },
                  child: Container(
                    width: 72.w,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: color.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32.r,
                          height: 32.r,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconFromName(type['icon'] as String),
                            color: Colors.white,
                            size: 16.r,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          type['label'] as String,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => setState(() => _state = ReportState.idle),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Center(
                child: Text(
                  'Cancelar',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingButton() {
    final theme = Theme.of(context);
    final selectedTypeData = incidentTypes.firstWhere(
          (t) => t['tipo'] == _selectedType,
      orElse: () => incidentTypes.first,
    );
    final color = _getColorFromHex(selectedTypeData['color'] as String);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 24.r,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconFromName(selectedTypeData['icon'] as String),
                  color: Colors.white,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  selectedTypeData['label'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_recording) ...[
                SizedBox(width: 8.w),
                Text(
                  '$_timer s',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
          
          if (_recording && _words.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                _words,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () {
              if (_recording) {
                _stopRecording();
              } else {
                _startRecording();
              }
            },
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _recording
                          ? [theme.colorScheme.error, theme.colorScheme.error.withOpacity(0.8)]
                          : [theme.colorScheme.primary, theme.colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: _recording ? [
                      BoxShadow(
                        color: theme.colorScheme.error.withOpacity(0.3 * _pulseController.value),
                        blurRadius: 12.r,
                        spreadRadius: 4.r,
                      )
                    ] : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _recording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _recording ? 'Detener y enviar' : 'Clic para grabar audio',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () {
              setState(() {
                _state = ReportState.selecting;
                _recording = false;
                _speech.stop();
              });
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Center(
                child: Text(
                  'Cancelar',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentConfirmation() {
    final theme = Theme.of(context);
    final selectedTypeData = incidentTypes.firstWhere(
          (t) => t['tipo'] == _selectedType,
      orElse: () => incidentTypes.first,
    );

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 24.r,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: AppColors.success, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Reporte enviado!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _words.isNotEmpty 
                      ? _words 
                      : "${selectedTypeData['label']} · Enviado correctamente",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum ReportState { idle, selecting, recording, sent }
