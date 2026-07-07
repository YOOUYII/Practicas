package com.example.wearable_app

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val TAG     = "MainActivity"
        const val CHANNEL = "com.example.wearable_app/ble_server"
        const val REQUEST_PERMISSIONS = 1001
    }

    private var bleServer: BleGattServer? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestBluetoothPermissions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        )

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {

                "startServer" -> {
                    try {
                        android.util.Log.d("MainActivity", "Iniciando BLE server...")
                        startBleServer()
                        android.util.Log.d("MainActivity", "BLE server iniciado OK")
                        result.success(null)
                    } catch (e: Exception) {
                        android.util.Log.e("MainActivity", "Error startServer: ${e.message}")
                        result.error("BLE_ERROR", e.message, null)
                    }
                }

                "stopServer" -> {
                    bleServer?.stop()
                    bleServer = null
                    result.success(null)
                }

                "notifySteps" -> {
                    val value = call.argument<Int>("value") ?: 0
                    bleServer?.notifySteps(value)
                    result.success(null)
                }

                "notifyHeartRate" -> {
                    val value = call.argument<Int>("value") ?: 0
                    bleServer?.notifyHeartRate(value)
                    result.success(null)
                }

                "notifyCalories" -> {
                    val value = call.argument<Int>("value") ?: 0
                    bleServer?.notifyCalories(value)
                    result.success(null)
                }

                "notifyStatus" -> {
                    val value = call.argument<String>("value") ?: "reposo"
                    bleServer?.notifyStatus(value)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startBleServer() {
        val btManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        val btAdapter = btManager.adapter

        if (!btAdapter.isEnabled) {
            throw Exception("Bluetooth no está encendido")
        }

        if (!hasBluetoothPermissions()) {
            throw Exception("Faltan permisos Bluetooth")
        }

        bleServer = BleGattServer(this)
        bleServer?.start()
        Log.d(TAG, "BleGattServer iniciado desde MainActivity")
    }

    private fun hasBluetoothPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) ==
                    PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE) ==
                    PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val permissions = arrayOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_ADVERTISE,
                Manifest.permission.ACCESS_FINE_LOCATION
            )
            val missing = permissions.filter {
                ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
            }
            if (missing.isNotEmpty()) {
                ActivityCompat.requestPermissions(this, missing.toTypedArray(), REQUEST_PERMISSIONS)
            }
        } else {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                    REQUEST_PERMISSIONS
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_PERMISSIONS) {
            val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            Log.d(TAG, "Permisos ${if (allGranted) "concedidos" else "denegados"}")
        }
    }

    override fun onDestroy() {
        bleServer?.stop()
        super.onDestroy()
    }
}