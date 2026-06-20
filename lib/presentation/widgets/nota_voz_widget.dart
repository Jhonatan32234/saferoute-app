import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
    super.dispose();
  }

  Future<void> _inicializarSpeech() async {
    _speechDisponible = await _stt.initialize(
      onStatus: (status) {
        // Solo detener si todavía figura como escuchando
        if (status == 'done' && _escuchando && _texto.isNotEmpty) {
          _detenerEscucha();
        }
      },
      onError: (error) => debugPrint('Speech error: $error'),
    );
    if (mounted) setState(() {});
  }

  Future<void> _iniciarEscucha() async {
    if (!_speechDisponible) return;
    setState(() {
      _escuchando = true;
      _texto = '';
    });

    await _stt.listen(
      onResult: (result) {
        setState(() => _texto = result.recognizedWords);
        _timerSilencio?.cancel();
        _timerSilencio = Timer(const Duration(seconds: 2), () {
          if (_escuchando && _texto.isNotEmpty) _detenerEscucha();
        });
      },
      localeId: 'es_MX',
      listenMode: stt.ListenMode.dictation,
    );
  }

  void _detenerEscucha() {
    if (!_escuchando) return; // Evita llamadas dobles
    _timerSilencio?.cancel();
    _stt.stop();
    setState(() => _escuchando = false);
    if (_texto.isNotEmpty) {
      widget.onTextoListo(_texto);
    }
  }

  void _cancelar() {
    _timerSilencio?.cancel();
    _stt.cancel();
    setState(() {
      _escuchando = false;
      _texto = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_speechDisponible) return const SizedBox.shrink();

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
          onLongPress: _escuchando ? null : _iniciarEscucha,
          onLongPressUp: _escuchando ? _detenerEscucha : null,
          child: Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              color: _escuchando ? Colors.red : Colors.grey[800],
              shape: BoxShape.circle,
              border: _escuchando ? Border.all(color: Colors.redAccent, width: 3) : null,
            ),
            child: Icon(_escuchando ? Icons.mic : Icons.mic_none, color: Colors.white, size: 42),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _escuchando ? 'Suelta para enviar' : 'Mantén para grabar',
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
