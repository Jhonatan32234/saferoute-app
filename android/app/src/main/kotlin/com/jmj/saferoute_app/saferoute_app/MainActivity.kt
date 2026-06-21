package com.jmj.saferoute_app.saferoute_app

import android.view.WindowManager
import android.os.Bundle
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.provider.Settings
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val GPS_CHANNEL = "com.jmj.saferoute/gps"
    private val USB_DEBUG_CHANNEL = "com.jmj.saferoute/usb_debug"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Bloqueo de capturas de pantalla y grabación (Medida RASP)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Canal para detección de Fake GPS
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GPS_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkFakeGPS") {
                checkMockLocationLive { isMock, info ->
                    result.success(if (isMock) info else "CLEAN")
                }
            } else {
                result.notImplemented()
            }
        }

        // Canal para detección de USB Debugging
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, USB_DEBUG_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUSBDebugging" -> {
                    result.success(isUSBDebuggingEnabled())
                }
                "openDeveloperSettings" -> {
                    abrirAjustesDesarrollador()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Notificar a Flutter cada vez que la app vuelve al primer plano
        flutterEngine?.let { engine ->
            // Actualización de USB Debugging
            val usbChannel = MethodChannel(engine.dartExecutor.binaryMessenger, USB_DEBUG_CHANNEL)
            usbChannel.invokeMethod("onUpdateDebugStatus", isUSBDebuggingEnabled())

            // Actualización de Fake GPS proactiva al volver a la app
            checkMockLocationLive { isMock, info ->
                val gpsChannel = MethodChannel(engine.dartExecutor.binaryMessenger, GPS_CHANNEL)
                gpsChannel.invokeMethod("onUpdateFakeGpsStatus", if (isMock) info else "CLEAN")
            }
        }
    }

    private fun isUSBDebuggingEnabled(): Boolean {
        return try {
            val adbEnabled = Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED, 0)
            adbEnabled == 1
        } catch (e: Exception) {
            // RASP: Si no podemos verificar, bloqueamos por seguridad
            true
        }
    }

    private fun abrirAjustesDesarrollador() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            try {
                val intent = Intent(Settings.ACTION_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (e2: Exception) {}
        }
    }

    private fun checkMockLocationLive(callback: (Boolean, String) -> Unit) {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        try {
            val providers = locationManager.getProviders(true)
            if (providers.isEmpty()) {
                callback(false, "CLEAN")
                return
            }

            val handler = android.os.Handler(android.os.Looper.getMainLooper())
            var hasResponded = false

            val locationListener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    val isMock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        location.isMock
                    } else {
                        @Suppress("DEPRECATION")
                        location.extras?.getBoolean("mockLocation", false) == true
                    }

                    if (isMock && !hasResponded) {
                        hasResponded = true
                        handler.removeCallbacksAndMessages(null)
                        locationManager.removeUpdates(this)
                        callback(true, "GPS Falso detectado: ${location.provider} (SIMULADO)")
                    } else if (!hasResponded && location.provider == LocationManager.GPS_PROVIDER) {
                        hasResponded = true
                        handler.removeCallbacksAndMessages(null)
                        locationManager.removeUpdates(this)
                        callback(false, "CLEAN")
                    }
                }
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
            }

            handler.postDelayed({
                if (!hasResponded) {
                    hasResponded = true
                    locationManager.removeUpdates(locationListener)
                    val lastGpsLoc = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
                    val isMockCache = if (lastGpsLoc != null) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) lastGpsLoc.isMock 
                        else @Suppress("DEPRECATION") lastGpsLoc.extras?.getBoolean("mockLocation", false) == true
                    } else false
                    
                    if (isMockCache) {
                        callback(true, "Respaldo Cache -> Detectado Simulador Pasivo")
                    } else {
                        callback(false, "CLEAN")
                    }
                }
            }, 3500)

            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestSingleUpdate(LocationManager.NETWORK_PROVIDER, locationListener, android.os.Looper.getMainLooper())
            }
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestSingleUpdate(LocationManager.GPS_PROVIDER, locationListener, android.os.Looper.getMainLooper())
            }
        } catch (e: SecurityException) {
            callback(true, "Error de Permisos: Ubicación desactivada.")
        } catch (e: Exception) {
            callback(false, "CLEAN")
        }
    }
}
