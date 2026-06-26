// lib/presentation/widgets/nota_voz_widget.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

class NotaVozWidget extends StatefulWidget {
  final Function(String textoTranscrito) onTextoListo;

  const NotaVozWidget({super.key, required this.onTextoListo});

  @override
  State<NotaVozWidget> createState() => _NotaVozWidgetState();
}

class _NotaVozWidgetState extends State<NotaVozWidget>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _escuchando = false;
  bool _speechDisponible = false;
  String _texto = '';
  String _textoFinal = '';
  Timer? _timerSilencio;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _inicializarSpeech();
  }

  @override
  void dispose() {
    _timerSilencio?.cancel();
    _pulseController.dispose();
    _stt.cancel();
    super.dispose();
  }

  Future<void> _inicializarSpeech() async {
    try {
      _speechDisponible = await _stt.initialize(
        onStatus: (status) {
          debugPrint('🎤 STT Status: $status');
          if (status == 'notListening' || status == 'done') {
            if (mounted && _escuchando) {
              _detenerEscucha();
            }
          }
        },
        onError: (error) async {
          debugPrint('🎤 STT Error: ${error.errorMsg}');
          if (mounted) {
            setState(() => _escuchando = false);
            final connectivity = await Connectivity().checkConnectivity();
            final bool estaOffline = connectivity.contains(ConnectivityResult.none);
            if (estaOffline && (error.errorMsg.contains('error_network') ||
                error.errorMsg.contains('error_client'))) {
              _mostrarAyudaOffline();
            }
          }
        },
      );
      debugPrint('🎤 Speech disponible: $_speechDisponible');
    } catch (e) {
      debugPrint('🎤 Error inicializando speech: $e');
      _speechDisponible = false;
    }
    if (mounted) setState(() {});
  }

  void _mostrarAyudaOffline() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.slate800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.mic_off, color: AppColors.warning, size: 36.r),
            SizedBox(height: 12.h),
            Text(
              'Dictado por voz sin internet',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Para que el micrófono funcione sin conexión, tu teléfono necesita activar el reconocimiento de voz local de Google.',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _abrirAjustesVoz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Configurar ahora', style: TextStyle(fontSize: 14.sp)),
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Lo haré después',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.5),
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirAjustesVoz() async {
    if (Platform.isAndroid) {
      try {
        const intent = AndroidIntent(
            action: 'com.google.android.voicesearch.action.RECOGNITION_SERVICE_SETTINGS'
        );
        await intent.launch();
      } catch (_) {
        const intentFallback = AndroidIntent(
            action: 'android.settings.VOICE_INPUT_SETTINGS'
        );
        await intentFallback.launch();
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _iniciarEscucha() async {
    await _stt.cancel();
    _timerSilencio?.cancel();

    if (!_speechDisponible) {
      await _inicializarSpeech();
      if (!_speechDisponible) return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    final bool estaOffline = connectivity.contains(ConnectivityResult.none);

    setState(() {
      _texto = '';
      _textoFinal = '';
    });

    try {
      await _stt.listen(
        onResult: (result) {
          debugPrint('🎤 Resultado parcial: "${result.recognizedWords}"');
          if (mounted) {
            setState(() {
              _texto = result.recognizedWords;
              // ✅ SIEMPRE guardar el texto final cuando llegue
              if (result.finalResult) {
                _textoFinal = result.recognizedWords;
                debugPrint('🎤 Texto FINAL guardado: "$_textoFinal"');
              }
            });
          }
          // Reiniciar timer de silencio
          _timerSilencio?.cancel();
          _timerSilencio = Timer(const Duration(seconds: 3), () {
            if (mounted && _escuchando) {
              debugPrint('🎤 Silencio detectado, deteniendo...');
              _detenerEscucha();
            }
          });
        },
        localeId: 'es_MX',
        listenMode: stt.ListenMode.dictation,
        listenOptions: stt.SpeechListenOptions(
          onDevice: estaOffline,
          partialResults: true,
          cancelOnError: false,
          autoPunctuation: true,
        ),
      );

      if (mounted) {
        setState(() => _escuchando = true);
      }
    } catch (e) {
      debugPrint('🎤 Error al iniciar escucha: $e');
      if (mounted) setState(() => _escuchando = false);
    }
  }

  void _detenerEscucha() {
    if (!_escuchando) return;

    _timerSilencio?.cancel();

    // ✅ Usar el texto final si existe, o el texto parcial
    String textoParaEnviar = _textoFinal.isNotEmpty ? _textoFinal : _texto;
    textoParaEnviar = textoParaEnviar.trim();

    debugPrint('🎤 Texto a enviar: "$textoParaEnviar"');
    debugPrint('🎤 _textoFinal: "$_textoFinal"');
    debugPrint('🎤 _texto: "$_texto"');

    _stt.stop();

    if (mounted) {
      setState(() => _escuchando = false);
    }

    // ✅ Enviar el texto transcrito, o un mensaje por defecto
    if (textoParaEnviar.isNotEmpty) {
      widget.onTextoListo(textoParaEnviar);
    } else {
      // Si no hay texto, usar un mensaje por defecto
      widget.onTextoListo('Reporte de incidente vial en la zona');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_speechDisponible) {
      return IconButton(
        icon: Icon(Icons.mic_off, color: AppColors.slate400, size: 42.r),
        onPressed: _inicializarSpeech,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_escuchando) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.danger.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic, color: AppColors.danger, size: 16.r),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    _texto.isEmpty ? 'Escuchando...' : _texto,
                    style: TextStyle(
                      color: AppColors.slate700,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_texto.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  Container(
                    width: 6.r,
                    height: 6.r,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],
        GestureDetector(
          onLongPress: _iniciarEscucha,
          onLongPressUp: _detenerEscucha,
          onLongPressCancel: _detenerEscucha,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 84.r,
                height: 84.r,
                decoration: BoxDecoration(
                  color: _escuchando ? AppColors.danger : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: _escuchando ? [
                    BoxShadow(
                      color: AppColors.danger.withOpacity(0.4 + _pulseController.value * 0.3),
                      blurRadius: 20.r + _pulseController.value * 10,
                      spreadRadius: 5 + _pulseController.value * 3,
                    ),
                  ] : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12.r,
                      spreadRadius: 2,
                    ),
                  ],
                  border: _escuchando
                      ? Border.all(color: AppColors.white, width: 2.r)
                      : null,
                ),
                child: Icon(
                  _escuchando ? Icons.mic : Icons.mic_none,
                  color: AppColors.white,
                  size: 42.r,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          _escuchando ? 'Suelta para enviar' : 'Mantén para hablar',
          style: TextStyle(
            color: AppColors.white.withOpacity(0.7),
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}