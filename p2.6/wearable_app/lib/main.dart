import 'dart:async';
import 'package:flutter/material.dart';
import 'sensor_simulator.dart';
import 'ble_server.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WearableApp());
}

class WearableApp extends StatefulWidget {
  const WearableApp({super.key});
  @override
  State<WearableApp> createState() => _WearableAppState();
}

class _WearableAppState extends State<WearableApp> {
  late final SensorSimulator _sim;
  late final BleServer       _server;

  // Guardar referencias de subscripciones
  final List<StreamSubscription> _streamSubs = [];

  int    _steps     = 0;
  int    _heartRate = 72;
  int    _calories  = 0;
  String _status    = 'reposo';
  bool   _active    = false;
  String _bleStatus = 'Listo';

  @override
  void initState() {
    super.initState();
    _sim    = SensorSimulator();
    _server = BleServer(_sim);
    _subscribeStreams();
  }

  void _subscribeStreams() {
    _streamSubs.add(
      _sim.stepsStream.listen((v) => setState(() => _steps = v)),
    );
    _streamSubs.add(
      _sim.heartRateStream.listen((v) => setState(() => _heartRate = v)),
    );
    _streamSubs.add(
      _sim.caloriesStream.listen((v) => setState(() => _calories = v)),
    );
    _streamSubs.add(
      _sim.statusStream.listen((v) => setState(() => _status = v)),
    );
  }

  Future<void> _toggleActivity() async {
    if (_active) {
      await _server.stop();
      setState(() {
        _active    = false;
        _bleStatus = 'Detenido';
      });
    } else {
      _sim.start();
      setState(() {
        _active    = true;
        _bleStatus = 'Iniciando BLE...';
      });
      try {
        await _server.startAdvertising();
        setState(() => _bleStatus = 'BLE activo ✓');
      } catch (e) {
        setState(() => _bleStatus = 'Error: $e');
      }
    }
  }

  @override
  void dispose() {
    // Cancelar todas las subscripciones de UI
    for (final s in _streamSubs) {
      s.cancel();
    }
    _streamSubs.clear();
    // Dispose completo del simulador (cierra streams)
    _sim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_heartRate',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: _heartRate > 120 ? Colors.red : Colors.white,
                    ),
                  ),
                  const Text('bpm',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('$_steps pasos',
                      style: const TextStyle(fontSize: 13, color: Colors.green)),
                  Text('$_calories kcal',
                      style: const TextStyle(fontSize: 14, color: Colors.amber)),
                  Text(_status,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 90,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: _toggleActivity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _active ? Colors.red : Colors.green,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        _active ? 'Detener' : 'Iniciar',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _bleStatus,
                    style: const TextStyle(fontSize: 10, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}