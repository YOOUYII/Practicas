package com.example.wearable_app

import android.bluetooth.*
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.ParcelUuid
import android.util.Log
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.UUID

class BleGattServer(private val context: Context) {

    companion object {
        const val TAG = "BleGattServer"

        val SERVICE_UUID    = UUID.fromString("12345678-1234-1234-1234-123456789abc")
        val STEPS_UUID      = UUID.fromString("aaaaaaaa-0001-1234-1234-123456789abc")
        val HEART_RATE_UUID = UUID.fromString("aaaaaaaa-0002-1234-1234-123456789abc")
        val CALORIES_UUID   = UUID.fromString("aaaaaaaa-0003-1234-1234-123456789abc")
        val STATUS_UUID     = UUID.fromString("aaaaaaaa-0004-1234-1234-123456789abc")
        val CCCD_UUID       = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")
    }

    private val bluetoothManager =
        context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter = bluetoothManager.adapter

    private var gattServer: BluetoothGattServer? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private val subscribedDevices = mutableSetOf<BluetoothDevice>()

    // Características BLE
    private lateinit var stepsChar:     BluetoothGattCharacteristic
    private lateinit var heartRateChar: BluetoothGattCharacteristic
    private lateinit var caloriesChar:  BluetoothGattCharacteristic
    private lateinit var statusChar:    BluetoothGattCharacteristic

    // Callback del servidor GATT
    private val gattServerCallback = object : BluetoothGattServerCallback() {

        override fun onConnectionStateChange(device: BluetoothDevice, status: Int, newState: Int) {
            when (newState) {
                BluetoothProfile.STATE_CONNECTED -> {
                    Log.d(TAG, "Dispositivo conectado: ${device.address}")
                    subscribedDevices.add(device)
                }
                BluetoothProfile.STATE_DISCONNECTED -> {
                    Log.d(TAG, "Dispositivo desconectado: ${device.address}")
                    subscribedDevices.remove(device)
                }
            }
        }

        override fun onCharacteristicReadRequest(
            device: BluetoothDevice, requestId: Int, offset: Int,
            characteristic: BluetoothGattCharacteristic
        ) {
            gattServer?.sendResponse(device, requestId,
                BluetoothGatt.GATT_SUCCESS, 0, characteristic.value)
        }

        override fun onDescriptorWriteRequest(
            device: BluetoothDevice, requestId: Int,
            descriptor: BluetoothGattDescriptor,
            preparedWrite: Boolean, responseNeeded: Boolean,
            offset: Int, value: ByteArray
        ) {
            // El teléfono activa las notificaciones escribiendo en el CCCD
            if (descriptor.uuid == CCCD_UUID) {
                if (value.contentEquals(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE)) {
                    Log.d(TAG, "NOTIFY activado por: ${device.address}")
                    subscribedDevices.add(device)
                } else {
                    Log.d(TAG, "NOTIFY desactivado por: ${device.address}")
                    subscribedDevices.remove(device)
                }
                descriptor.value = value
            }
            if (responseNeeded) {
                gattServer?.sendResponse(device, requestId,
                    BluetoothGatt.GATT_SUCCESS, 0, null)
            }
        }
    }

    // Callback del advertising
    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
            Log.d(TAG, "Advertising iniciado correctamente")
        }
        override fun onStartFailure(errorCode: Int) {
            Log.e(TAG, "Error al iniciar advertising: $errorCode")
        }
    }

    fun start() {
        if (!bluetoothAdapter.isEnabled) {
            Log.e(TAG, "Bluetooth no está encendido")
            return
        }

        // Crear característica auxiliar
        fun makeChar(uuid: UUID): BluetoothGattCharacteristic {
            val char = BluetoothGattCharacteristic(
                uuid,
                BluetoothGattCharacteristic.PROPERTY_READ or
                BluetoothGattCharacteristic.PROPERTY_NOTIFY,
                BluetoothGattCharacteristic.PERMISSION_READ
            )
            val cccd = BluetoothGattDescriptor(
                CCCD_UUID,
                BluetoothGattDescriptor.PERMISSION_READ or
                BluetoothGattDescriptor.PERMISSION_WRITE
            )
            cccd.value = BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            char.addDescriptor(cccd)
            return char
        }

        // Crear las 4 características
        stepsChar     = makeChar(STEPS_UUID)
        heartRateChar = makeChar(HEART_RATE_UUID)
        caloriesChar  = makeChar(CALORIES_UUID)
        statusChar    = makeChar(STATUS_UUID)

        // Crear servicio GATT
        val service = BluetoothGattService(
            SERVICE_UUID,
            BluetoothGattService.SERVICE_TYPE_PRIMARY
        ).apply {
            addCharacteristic(stepsChar)
            addCharacteristic(heartRateChar)
            addCharacteristic(caloriesChar)
            addCharacteristic(statusChar)
        }

        // Abrir servidor GATT
        gattServer = bluetoothManager.openGattServer(context, gattServerCallback)
        gattServer?.addService(service)

        // Iniciar advertising
        startAdvertising()
        Log.d(TAG, "Servidor GATT iniciado")
    }

    private fun startAdvertising() {
        advertiser = bluetoothAdapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            Log.e(TAG, "BluetoothLeAdvertiser no disponible")
            return
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(true)
            .build()

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(true)
            .addServiceUuid(ParcelUuid(SERVICE_UUID))
            .build()

        advertiser?.startAdvertising(settings, data, advertiseCallback)
    }

    fun stop() {
        advertiser?.stopAdvertising(advertiseCallback)
        gattServer?.close()
        gattServer = null
        subscribedDevices.clear()
        Log.d(TAG, "Servidor GATT detenido")
    }

    // Notificar pasos (4 bytes little-endian)
    fun notifySteps(value: Int) {
        val bytes = ByteBuffer.allocate(4)
            .order(ByteOrder.LITTLE_ENDIAN)
            .putInt(value)
            .array()
        notify(stepsChar, bytes)
    }

    // Notificar ritmo cardíaco (1 byte)
    fun notifyHeartRate(value: Int) {
        notify(heartRateChar, byteArrayOf(value.toByte()))
    }

    // Notificar calorías (2 bytes little-endian)
    fun notifyCalories(value: Int) {
        val bytes = ByteBuffer.allocate(2)
            .order(ByteOrder.LITTLE_ENDIAN)
            .putShort(value.toShort())
            .array()
        notify(caloriesChar, bytes)
    }

    // Notificar estado (UTF-8)
    fun notifyStatus(value: String) {
        notify(statusChar, value.toByteArray(Charsets.UTF_8))
    }

    private fun notify(characteristic: BluetoothGattCharacteristic, value: ByteArray) {
        characteristic.value = value
        subscribedDevices.forEach { device ->
            try {
                gattServer?.notifyCharacteristicChanged(device, characteristic, false)
            } catch (e: Exception) {
                Log.e(TAG, "Error notificando a ${device.address}: $e")
            }
        }
    }
}