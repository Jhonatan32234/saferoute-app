import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../security/usb_debug_checker.dart';

class UsbDebugBlocker extends StatefulWidget {
  final Widget child;

  const UsbDebugBlocker({super.key, required this.child});

  @override
  State<UsbDebugBlocker> createState() => _UsbDebugBlockerState();
}

class _UsbDebugBlockerState extends State<UsbDebugBlocker> with WidgetsBindingObserver {
  bool _isBlocked = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Escuchar actualizaciones desde Android (onResume)
    UsbDebugChecker.setUpdateHandler((isEnabled) {
      debugPrint('USB Debug Status Update: $isEnabled');
      if (mounted) {
        setState(() {
          _isBlocked = isEnabled;
          _checking = false;
        });
      }
    });

    _checkUsbDebug();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUsbDebug();
    }
  }

  Future<void> _checkUsbDebug() async {
    try {
      final isEnabled = await UsbDebugChecker.isUsbDebugEnabled();
      debugPrint('USB Debug Initial Check: $isEnabled');
      if (mounted) {
        setState(() {
          _isBlocked = isEnabled;
          _checking = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking USB debug: $e');
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isBlocked) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF8E0000), // Rojo oscuro de seguridad
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.usb_off, size: 100, color: Colors.white),
                    const SizedBox(height: 24),
                    const Text(
                      '⚠️ DEPURACIÓN USB DETECTADA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRiskCard(),
                    const SizedBox(height: 24),
                    _buildInstructionsCard(),
                    const SizedBox(height: 32),
                    _buildActionButton(),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => SystemNavigator.pop(),
                      icon: const Icon(Icons.exit_to_app, color: Colors.white70),
                      label: const Text('CERRAR APLICACIÓN', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }

  Widget _buildRiskCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riesgo de Seguridad:',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'La depuración USB permite que herramientas externas accedan a los datos de la app. SafeRoute bloquea el acceso para proteger tu información sensible y ubicación.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Text(
            '¿Cómo solucionarlo?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            '1. Abre Ajustes > Opciones de desarrollador\n2. Busca "Depuración USB"\n3. Desactiva el interruptor\n4. Regresa a la aplicación',
            textAlign: TextAlign.left,
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => UsbDebugChecker.openDeveloperSettings(),
        icon: const Icon(Icons.settings_applications),
        label: const Text('IR A OPCIONES DE DESARROLLADOR'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF8E0000),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
