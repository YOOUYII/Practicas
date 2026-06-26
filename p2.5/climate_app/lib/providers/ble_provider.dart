import 'package:flutter/material.dart';

// AGREGADO: el PDF importa BLEProvider en main.dart pero no da su codigo.
// Esta clase minima permite que la app compile. La logica BLE completa
// viene de P2.4 en weather_provider.dart.
class BLEProvider extends ChangeNotifier {
  bool _bleConnected = false;
  String _bleStatus = 'Sin conexion BLE';

  bool get bleConnected => _bleConnected;
  String get bleStatus => _bleStatus;

  void updateStatus(String status) {
    _bleStatus = status;
    notifyListeners();
  }
}