import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'sensor_simulator.dart';

class BleServer {
  final SensorSimulator simulator;
  bool _advertising = false;
  final List<StreamSubscription> _subs = [];

  static const _channel = MethodChannel('com.example.wearable_app/ble_server');

  BleServer(this.simulator);

  bool get isAdvertising => _advertising;

  Future<void> startAdvertising() async {
    try {
      // Iniciar servidor GATT nativo en Kotlin
      await _channel.invokeMethod('startServer');
      _advertising = true;
      debugPrint('[BleServer] Servidor GATT nativo iniciado');

      // Conectar streams del simulador con notificaciones nativas
      _subs.add(simulator.stepsStream.listen((steps) async {
        try {
          await _channel.invokeMethod('notifySteps', {'value': steps});
        } catch (e) {
          debugPrint('[BleServer] Error notifySteps: $e');
        }
      }));

      _subs.add(simulator.heartRateStream.listen((bpm) async {
        try {
          await _channel.invokeMethod('notifyHeartRate', {'value': bpm});
        } catch (e) {
          debugPrint('[BleServer] Error notifyHeartRate: $e');
        }
      }));

      _subs.add(simulator.caloriesStream.listen((cal) async {
        try {
          await _channel.invokeMethod('notifyCalories', {'value': cal});
        } catch (e) {
          debugPrint('[BleServer] Error notifyCalories: $e');
        }
      }));

      _subs.add(simulator.statusStream.listen((status) async {
        try {
          await _channel.invokeMethod('notifyStatus', {'value': status});
        } catch (e) {
          debugPrint('[BleServer] Error notifyStatus: $e');
        }
      }));

    } catch (e) {
      _advertising = false;
      debugPrint('[BleServer] Error iniciando servidor: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    _advertising = false;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    try {
      await _channel.invokeMethod('stopServer');
    } catch (e) {
      debugPrint('[BleServer] Error deteniendo servidor: $e');
    }
    simulator.stop();
  }
}