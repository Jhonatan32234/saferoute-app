import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:android_intent_plus/android_intent.dart';

class NotaVozWidget extends StatefulWidget {
  final Function(String textoTranscrito) onTextoListo;

  const NotaVozWidget({super.key, required this.onTextoListo});

  @override
  State<NotaVozWidget> createState() => _NotaVozWidgetState();
}

class _NotaVozWidgetState extends State<NotaVozWidget>
    with SingleTickerProviderStateMixin {
  final _stt = stt.SpeechToText();
  bool _escuchando = false;
  bool _speechDisponible = false;
  String _texto = '';
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
          if (status == 'notListening' || status == 'done') {
            if (mounted && _escuchando) _detenerEscucha();
          }
        },
        onError: (error) async {
          debugPrint('STT Error: ${error.errorMsg}');
          if (mounted) {
            setState(() => _escuchando = false);

            final connectivity = await Connectivity().checkConnectivity();
            final bool estaOffline = connectivity.contains(ConnectivityResult.none);

            // Si falla por red estando offline, probablemente falta el paquete de idioma
            if (estaOffline && (error.errorMsg.contains('error_network') || error.errorMsg.contains('error_client'))) {
              _mostrarAyudaOffline();
            }
          }
        },
      );
    } catch (e) {
      _speechDisponible = false;
    }
    if (mounted) setState(() {});
  }

  void _mostrarAyudaOffline() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mic_off, color: Colors.amber, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Dictado por voz sin internet',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para que el micrófono funcione sin conexión, tu teléfono necesita '
                  'activar el reconocimiento de voz local de Google. Es una opción '
                  'gratuita del propio sistema Android.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _abrirAjustesVoz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Configurar ahora'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Lo haré después', style: TextStyle(color: Colors.white54)),
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
          action: 'com.google.android.voicesearch.action.RECOGNITION_SERVICE_SETTINGS',
        );
        await intent.launch();
      } catch (_) {
        const intentFallback = AndroidIntent(
          action: 'android.settings.VOICE_INPUT_SETTINGS',
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

    setState(() => _texto = '');

    try {
      await _stt.listen(
        onResult: (result) {
          if (mounted) setState(() => _texto = result.recognizedWords);
          _timerSilencio?.cancel();
          _timerSilencio = Timer(const Duration(seconds: 3), () {
            if (mounted && _escuchando && _texto.isNotEmpty) _detenerEscucha();
          });
        },
        localeId: 'es_MX',
        listenMode: stt.ListenMode.dictation,
        listenOptions: stt.SpeechListenOptions(
          onDevice: estaOffline,
          partialResults: true,
          cancelOnError: false,
        ),
      );
      if (mounted) setState(() => _escuchando = true);
    } catch (e) {
      if (mounted) setState(() => _escuchando = false);
    }
  }

  void _detenerEscucha() {
    if (!_escuchando) return;
    _timerSilencio?.cancel();
    final textoFinal = _texto;
    _stt.stop();
    if (mounted) setState(() => _escuchando = false);

    // Si no hay texto (error offline), se envía vacío para que el provider
    // use el tipo de reporte como descripción por defecto.
    widget.onTextoListo(textoFinal.trim());
  }

  @override
  Widget build(BuildContext context) {
    if (!_speechDisponible) {
      return IconButton(
        icon: const Icon(Icons.mic_off, color: Colors.grey, size: 42),
        onPressed: _inicializarSpeech,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_escuchando) ...[
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1 + _pulseController.value * 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: Colors.red, size: 16 + _pulseController.value * 4),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _texto.isEmpty ? 'Escuchando...' : _texto,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onLongPress: _iniciarEscucha,
          onLongPressUp: _detenerEscucha,
          child: Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              color: _escuchando ? Colors.red : Colors.grey[800],
              shape: BoxShape.circle,
              boxShadow: _escuchando ? [
                BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 15, spreadRadius: 5)
              ] : null,
              border: _escuchando ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Icon(_escuchando ? Icons.mic : Icons.mic_none, color: Colors.white, size: 42),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _escuchando ? 'Suelta para enviar' : 'Mantén para hablar',
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}