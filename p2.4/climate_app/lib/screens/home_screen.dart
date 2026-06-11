import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<WeatherProvider>(context, listen: false)
        .loadWeather('Santiago');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Climate')),
      body: Consumer<WeatherProvider>(
        builder: (context, weather, _) {
          if (weather.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (weather.errorMessage != null) {
            return Center(child: Text('Error: ${weather.errorMessage}'));
          }
          if (weather.weather == null) {
            return const Center(child: Text('No data'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Datos del clima
                Text(
                  '${weather.weather!.temperature}${weather.temperatureUnit}',
                  style: const TextStyle(
                      fontSize: 72, fontWeight: FontWeight.bold),
                ),
                Text(weather.weather!.city,
                    style: const TextStyle(fontSize: 24)),
                Text('Humidity: ${weather.weather!.humidity}%'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => weather.toggleTemperatureUnit(),
                  child: const Text('Cambiar unidad'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final selectedCity = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchScreen()),
                    );
                    if (selectedCity != null) {
                      Provider.of<WeatherProvider>(context, listen: false)
                          .loadWeather(selectedCity);
                    }
                  },
                  child: const Text('Buscar Ciudades'),
                ),

                const Divider(height: 32),

                // Estado BLE
                Text(
                  weather.bleStatus,
                  style: TextStyle(
                    color: weather.bleConnected ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Paso 11: botón Buscar dispositivos BLE
                Column(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Buscar dispositivos BLE'),
                      onPressed: weather.isScanning
                          ? null
                          : () => weather.startBLEScan(),
                    ),
                    if (weather.isScanning)
                      ElevatedButton(
                        onPressed: () => weather.stopBLEScan(),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        child: const Text('Detener búsqueda'),
                      ),
                    if (weather.bleConnected)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.bluetooth_disabled),
                        label: const Text('Desconectar'),
                        onPressed: () => weather.disconnectBLE(),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                      ),
                  ],
                ),

                // Paso 12: estado de carga mientras conecta y lee GATT
                if (weather.isScanning || weather.isReadingBLE)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 12),
                        Text('Conectando...'),
                      ],
                    ),
                  ),

                // Paso 11: lista de dispositivos encontrados
                if (weather.scanResults.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Dispositivos encontrados:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: weather.scanResults.length,
                    itemBuilder: (context, index) {
                      final result = weather.scanResults[index];
                      final name = result.device.platformName.isEmpty
                          ? 'Dispositivo desconocido'
                          : result.device.platformName;
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(name),
                        subtitle: Text(result.device.remoteId.toString()),
                        trailing: Text('${result.rssi} dBm'),
                        // Paso 12: al tocar conecta y lee datos
                        onTap: () => weather.connectToDevice(result.device),
                      );
                    },
                  ),
                ],

                // Paso 13: sin conexión BLE
                if (!weather.bleConnected &&
                    !weather.isScanning &&
                    !weather.isReadingBLE &&
                    weather.scanResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Sin conexion BLE',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}