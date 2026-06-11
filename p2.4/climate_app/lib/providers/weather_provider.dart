import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/ble_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class WeatherProvider extends ChangeNotifier {
  Weather? _weather;
  bool _isLoading = false;
  String? _errorMessage;
  int _tempUnit = 0; // 0 = Celsius, 1 = Fahrenheit

  // Paso 10: estado BLE
  final BLEService _bleService = BLEService();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _bleConnected = false;
  bool _isReadingBLE = false; // estado de carga al leer características
  String _bleStatus = 'Sin conexion BLE';

  // Getters
  Weather? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get temperatureUnit => _tempUnit == 0 ? '°C' : '°F';

  // Getters BLE
  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  bool get bleConnected => _bleConnected;
  bool get isReadingBLE => _isReadingBLE;
  String get bleStatus => _bleStatus;

  // Cargar datos (simulado)
  Future<void> loadWeather(String city) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));
      _weather = Weather(
        city: city,
        temperature: 24,
        condition: 'cloudy',
        humidity: 65,
      );
    } catch (e) {
      _errorMessage = 'Error loading weather: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleTemperatureUnit() {
    _tempUnit = _tempUnit == 0 ? 1 : 0;
    notifyListeners();
  }

  void updateTemperature(int newTemp) {
    if (_weather != null) {
      _weather = Weather(
        city: _weather!.city,
        temperature: newTemp,
        condition: _weather!.condition,
        humidity: _weather!.humidity,
      );
      notifyListeners();
    }
  }

  // Paso 10: inicia scanning BLE
  Future<void> startBLEScan() async {
    if (Platform.isAndroid) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.locationWhenInUse.request();
    }

    _scanResults = [];
    _isScanning = true;
    _bleStatus = 'Buscando dispositivos...';
    notifyListeners();

    _bleService.scanForDevices().listen((results) {
      _scanResults = results;
      notifyListeners();
    }).onDone(() {
      _isScanning = false;
      notifyListeners();
    });
  }

  void stopBLEScan() {
    _bleService.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  // Paso 10 + 12: conecta al dispositivo y lee características GATT
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      _bleStatus = 'Conectando...';
      _isReadingBLE = true;
      notifyListeners();

      await _bleService.connect(device);
      _bleConnected = true;
      _bleStatus = 'Conectado a ${device.platformName}';
      notifyListeners();

      // Escucha desconexión - Paso 13
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _bleConnected = false;
          _bleStatus = 'Sin conexion BLE';
          notifyListeners();
        }
      });

      // Paso 10: lee temperatura (Char 1) y ciudad (Char 2) del wearable
      _bleStatus = 'Leyendo datos del dispositivo...';
      notifyListeners();

      final temp = await _bleService.readTemperature();
      final city = await _bleService.readCity();

      if (temp != null || city != null) {
        _weather = Weather(
          city: city ?? _weather?.city ?? 'Desconocida',
          temperature: temp ?? _weather?.temperature ?? 0,
          condition: _weather?.condition ?? 'clear',
          humidity: _weather?.humidity ?? 0,
        );
        _bleStatus =
            'BLE: ${city ?? ''} ${temp != null ? "$temp°C" : ""}';
      } else {
        _bleStatus = 'Conectado — sin datos válidos';
      }

      _isReadingBLE = false;
      notifyListeners();
    } catch (e) {
      _bleConnected = false;
      _isReadingBLE = false;
      _bleStatus = 'Error al conectar: $e';
      notifyListeners();
    }
  }

  // Paso 13: desconexión
  Future<void> disconnectBLE() async {
    await _bleService.disconnect();
    _bleConnected = false;
    _bleStatus = 'Sin conexion BLE';
    notifyListeners();
  }
}