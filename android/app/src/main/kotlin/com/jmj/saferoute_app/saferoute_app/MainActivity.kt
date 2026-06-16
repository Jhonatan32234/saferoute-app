package com.jmj.saferoute_app.saferoute_app

import android.view.WindowManager
import android.os.Bundle
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.jmj.saferoute/seguridad"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Anti captura de pantalla
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "checkFakeGPS") {
                    checkMockLocation { isMock, info ->
                        if (isMock) {
                            result.success(info)
                        } else {
                            result.success("CLEAN")
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun checkMockLocation(callback: (Boolean, String) -> Unit) {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        try {
            val providers = locationManager.getProviders(true)
            if (providers.isEmpty()) {
                callback(false, "CLEAN")
                return
            }

            val handler = android.os.Handler(android.os.Looper.getMainLooper())
            var hasResponded = false

            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    val isMock = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                        location.isMock
                    } else {
                        location.extras?.getBoolean("mockLocation", false) == true
                    }
                    if (isMock && !hasResponded) {
                        hasResponded = true
                        handler.removeCallbacksAndMessages(null)
                        locationManager.removeUpdates(this)
                        callback(true, "GPS Falso detectado: ${location.provider}")
                    }
                }
                override fun onStatusChanged(p: String?, s: Int, e: Bundle?) {}
                override fun onProviderEnabled(p: String) {}
                override fun onProviderDisabled(p: String) {}
            }

            handler.postDelayed({
                if (!hasResponded) {
                    hasResponded = true
                    locationManager.removeUpdates(listener)
                    callback(false, "CLEAN")
                }
            }, 3500)

            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestSingleUpdate(LocationManager.NETWORK_PROVIDER, listener, android.os.Looper.getMainLooper())
            }
            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestSingleUpdate(LocationManager.GPS_PROVIDER, listener, android.os.Looper.getMainLooper())
            }
        } catch (e: SecurityException) {
            callback(true, "Error de permisos")
        } catch (e: Exception) {
            callback(false, "CLEAN")
        }
    }
}
