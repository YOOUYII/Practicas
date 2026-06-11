import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// UUIDs del dispositivo simulado (configurados en LightBlue)
const String kServiceUUID = '12345678-1234-5678-1234-56789abcdef0';
const String kCharTemperatureUUID = '87654321-4321-6789-4321-fedcba987654';
const String kCharCityUUID = 'abcdef01-2345-6789-abcd-ef0123456789';

class BLEService {
  BluetoothDevice? _connectedDevice;

  // Normaliza UUID: quita guiones y pone en lowercase para comparar
  String _normalizeUuid(String uuid) {
    return uuid.toLowerCase().replaceAll('-', '');
  }

  // Paso 6: scanForDevices - devuelve Stream<ScanResult>
  Stream<List<ScanResult>> scanForDevices() {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    return FlutterBluePlus.scanResults;
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
  }

  // Paso 7: connect - conecta al dispositivo BLE especificado
  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    await device.connect(
      license: License.free,
      autoConnect: false,
      mtu: null,
    );
  }

  // Paso 7: disconnect
  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
  }

  // Paso 8 y 9: descubre servicios y lee caracteristica por UUID
  Future<String> readCharacteristic(String targetUuid) async {
    if (_connectedDevice == null) {
      return 'Sin conexion BLE';
    }

    final targetNormalized = _normalizeUuid(targetUuid);

    // Paso 8: descubre servicios
    List<BluetoothService> services =
        await _connectedDevice!.discoverServices();

    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic
          in service.characteristics) {
        // Criterio de seguridad: normaliza ambos UUIDs antes de comparar
        final charNormalized = _normalizeUuid(
          characteristic.uuid.toString(),
        );

        if (charNormalized == targetNormalized) {
          // Paso 9: lee el valor de la caracteristica
          List<int> value = await characteristic.read();
          String result = String.fromCharCodes(value);

          // Criterio de seguridad: valida longitud (city < 50 chars)
          if (result.length > 50) {
            return 'Dato invalido: demasiado largo';
          }

          return result;
        }
      }
    }

    return 'Caracteristica no encontrada';
  }

  // Lee temperatura (Char 1) y la valida en rango -60 a 60
  Future<int?> readTemperature() async {
    final raw = await readCharacteristic(kCharTemperatureUUID);
    final temp = int.tryParse(raw.trim());
    // Criterio de seguridad: valida rango de temperatura
    if (temp == null || temp < -60 || temp > 60) {
      return null;
    }
    return temp;
  }

  // Lee ciudad (Char 2)
  Future<String?> readCity() async {
    final raw = await readCharacteristic(kCharCityUUID);
    if (raw == 'Sin conexion BLE' ||
        raw == 'Caracteristica no encontrada' ||
        raw.startsWith('Dato invalido')) {
      return null;
    }
    return raw.trim();
  }

  BluetoothDevice? get connectedDevice => _connectedDevice;
}