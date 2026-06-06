import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../utils/weather_utils.dart';
import 'search_screen.dart';
import '../widgets/weather_icon.dart';

// AGREGADO: StatefulWidget (el PDF lo muestra así, hay que convertir desde P2.2)
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Del PDF: carga datos al abrir
    Provider.of<WeatherProvider>(context, listen: false)
        .loadWeather('Santiago');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima Actual'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // Del PDF: Consumer<WeatherProvider>
      body: Consumer<WeatherProvider>(
        builder: (context, weather, _) {
          // Del PDF: estado de carga
          if (weather.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Del PDF: estado de error
          if (weather.errorMessage != null) {
            return Center(child: Text('Error: ${weather.errorMessage}'));
          }

          // Del PDF: sin datos
          if (weather.weather == null) {
            return const Center(child: Text('No data'));
          }

          // AGREGADO: responsive con MediaQuery (mismo patrón de P2.2)
          final width = MediaQuery.of(context).size.width;
          final isLandscape = width > 600;

          // AGREGADO: conversión de temperatura usando WeatherUtils del PDF
          final tempDisplay = weather.temperatureUnit == '°F'
              ? '${WeatherUtils.celsiusToFahrenheit(weather.weather!.temperature).toStringAsFixed(1)}${weather.temperatureUnit}'
              : '${weather.weather!.temperature}${weather.temperatureUnit}';

          final content = [
            // Del PDF: temperatura con unidad dinámica
            Text(
              tempDisplay,
              style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const SizedBox(height: 8),
            // Del PDF: ciudad
            Text(
              weather.weather!.city,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 16),
            // AGREGADO: WeatherIcon reutilizable de P2.2
            WeatherIcon(condition: weather.weather!.condition, size: 100),
            const SizedBox(height: 24),
            // Del PDF: humedad
            Text(
              'Humedad: ${weather.weather!.humidity}%  |  Viento: 12 km/h',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            // Del PDF: botón cambiar unidad
            ElevatedButton(
              onPressed: () => weather.toggleTemperatureUnit(),
              child: Text(
                  'Cambiar a ${weather.temperatureUnit == '°C' ? '°F' : '°C'}'),
            ),
            const SizedBox(height: 12),
            // AGREGADO: botón buscar ciudades con Navigator.pop retornando ciudad
            ElevatedButton(
              onPressed: () async {
                final selectedCity = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SearchScreen()),
                );
                if (selectedCity != null) {
                  // AGREGADO: recarga el provider con la ciudad seleccionada
                  Provider.of<WeatherProvider>(context, listen: false)
                      .loadWeather(selectedCity);
                }
              },
              child: const Text('Buscar Ciudades'),
            ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: isLandscape
                // AGREGADO: layout landscape de P2.2
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: content.sublist(0, 4),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: content.sublist(4),
                      ),
                    ],
                  )
                // Portrait: columna centrada
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: content,
                  ),
          );
        },
      ),
    );
  }
}