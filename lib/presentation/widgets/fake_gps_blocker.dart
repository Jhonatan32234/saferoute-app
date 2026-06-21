import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/security/fake_gps_checker.dart';

class FakeGpsBlocker extends StatefulWidget {
  final Widget child;

  const FakeGpsBlocker({super.key, required this.child});

  @override
  State<FakeGpsBlocker> createState() => _FakeGpsBlockerState();
}

class _FakeGpsBlockerState extends State<FakeGpsBlocker> with WidgetsBindingObserver {
  bool _isBlocked = false;
  String _culpableInfo = "";
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFakeGps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-verificar cuando la app vuelve al primer plano
    if (state == AppLifecycleState.resumed) {
      _checkFakeGps();
    }
  }

  Future<void> _checkFakeGps() async {
    // Si ya estamos bloqueados, no mostramos el loading de nuevo para evitar parpadeo
    if (!_isBlocked) setState(() => _checking = true);
    
    final result = await FakeGpsChecker.checkFakeGps();
    
    if (mounted) {
      setState(() {
        _isBlocked = result != "CLEAN";
        _culpableInfo = result;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking && !_isBlocked) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF8E0000)),
              SizedBox(height: 16),
              Text('Verificando integridad del GPS...'),
            ],
          ),
        ),
      );
    }

    if (_isBlocked) {
      return PopScope(
        canPop: false, // Bloquea el botón físico de atrás
        child: Scaffold(
          backgroundColor: const Color(0xFF8E0000),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gpp_bad, size: 100, color: Colors.white),
                    const SizedBox(height: 24),
                    const Text(
                      'ENTORNO NO SEGURO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSecurityInfo(),
                    const SizedBox(height: 32),
                    _buildRetryButton(),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => SystemNavigator.pop(),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text('SALIR DE LA APP'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
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

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          const Text(
            'GPS Falso Detectado',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            'SafeRoute ha detectado que se están utilizando coordenadas simuladas. Detalle técnico: $_culpableInfo',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: _checkFakeGps,
      icon: const Icon(Icons.refresh),
      label: const Text('REINTENTAR VERIFICACIÓN'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF8E0000),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
