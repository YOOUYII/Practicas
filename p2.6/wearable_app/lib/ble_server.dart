import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'ble_constants.dart';
import 'sensor_simulator.dart';

class BleServer {
  final SensorSimulator simulator;
  bool _advertising = false;
  final List<StreamSubscription> _subs = [];

  BleServer(this.simulator);

  bool get isAdvertising => _advertising;

  Uint8List _intToBytes(int value) {
    final data = ByteData(4);
    data.setInt32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  Uint8List _int16ToBytes(int value) {
    final data = ByteData(2);
    data.setInt16(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  Future<void> startAdvertising() async {
    try {
      await BlePeripheral.initialize();

      // Callback: cuando el teléfono se suscribe o desuscribe
      BlePeripheral.setConnectionStateChangeCallback(
        (String deviceId, bool connected) {
          debugPrint('[BleServer] Telefono ${connected ? "conectado" : "desconectado"}: $deviceId');
        },
      );

      // Descriptor CCCD requerido para NOTIFY
      final cccd = BleDescriptor(
        uuid: '00002902-0000-1000-8000-00805f9b34fb',
        value: Uint8List.fromList([0, 0]),
      );

      // Registrar servicio GATT
      await BlePeripheral.addService(
        BleService(
          uuid: BleConstants.serviceUUID,
          primary: true,
          characteristics: [
            BleCharacteristic(
              uuid: BleConstants.stepsUUID,
              properties: [
                CharacteristicProperties.notify.index,
                CharacteristicProperties.read.index,
              ],
              permissions: [
                AttributePermissions.readable.index,
              ],
              value: _intToBytes(0),
              descriptors: [cccd],
            ),
            BleCharacteristic(
              uuid: BleConstants.heartRateUUID,
              properties: [
                CharacteristicProperties.notify.index,
                CharacteristicProperties.read.index,
              ],
              permissions: [
                AttributePermissions.readable.index,
              ],
              value: Uint8List.fromList([72]),
              descriptors: [cccd],
            ),
            BleCharacteristic(
              uuid: BleConstants.caloriesUUID,
              properties: [
                CharacteristicProperties.notify.index,
                CharacteristicProperties.read.index,
              ],
              permissions: [
                AttributePermissions.readable.index,
              ],
              value: _int16ToBytes(0),
              descriptors: [cccd],
            ),
            BleCharacteristic(
              uuid: BleConstants.statusUUID,
              properties: [
                CharacteristicProperties.notify.index,
                CharacteristicProperties.read.index,
              ],
              permissions: [
                AttributePermissions.readable.index,
              ],
              value: Uint8List.fromList(utf8.encode('reposo')),
              descriptors: [cccd],
            ),
          ],
        ),
      );

      // Iniciar advertising BLE real
      await BlePeripheral.startAdvertising(
        services: [BleConstants.serviceUUID],
        localName: 'ActivityWearable',
      );

      _advertising = true;
      debugPrint('[BleServer] Advertising iniciado. Esperando telefono...');

      // Conectar streams del simulador con notificaciones BLE
      _subs.add(simulator.stepsStream.listen((steps) async {
        await _notify(BleConstants.stepsUUID, _intToBytes(steps));
      }));

      _subs.add(simulator.heartRateStream.listen((bpm) async {
        await _notify(
            BleConstants.heartRateUUID, Uint8List.fromList([bpm]));
      }));

      _subs.add(simulator.caloriesStream.listen((cal) async {
        await _notify(BleConstants.caloriesUUID, _int16ToBytes(cal));
      }));

      _subs.add(simulator.statusStream.listen((status) async {
        await _notify(
          BleConstants.statusUUID,
          Uint8List.fromList(utf8.encode(status)),
        );
      }));
    } catch (e) {
      _advertising = false;
      debugPrint('[BleServer] Error: $e');
      rethrow;
    }
  }

  Future<void> _notify(String characteristicUuid, Uint8List value) async {
    if (!_advertising) return;
    try {
      // API correcta en v2.4.0
      await BlePeripheral.updateCharacteristic(
        characteristicId: characteristicUuid,
        value: value,
      );
    } catch (e) {
      debugPrint('[BleServer] Error notificando $characteristicUuid: $e');
    }
  }

  Future<void> stop() async {
    _advertising = false;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    try {
      await BlePeripheral.stopAdvertising();
    } catch (_) {}
    simulator.stop();
  }
}