import 'package:flutter/material.dart';
import 'search_screen.dart';
import '../widgets/weather_icon.dart';
import '../widgets/temperature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // AGREGADO: MediaQuery para responsive (el PDF da el snippet pero no lo integra)
    final width = MediaQuery.of(context).size.width;
    final isLandscape = width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima Actual'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( // AGREGADO: evita overflow en landscape
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isLandscape
              // AGREGADO: layout landscape (Row) - el PDF lo menciona pero no codifica
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Columna izquierda: temperatura y ciudad
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // AGREGADO: TemperatureCard widget reutilizable
                        TemperatureCard(temperature: '24°C', city: 'Santiago de Querétaro'),
                        const SizedBox(height: 16),
                        const Text(
                          'Humedad: 65% | Viento: 12 km/h',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SearchScreen()),
                            );
                          },
                          child: const Text('Buscar Ciudades'),
                        ),
                      ],
                    ),
                    // Columna derecha: ícono del clima
                    // AGREGADO: WeatherIcon widget reutilizable
                    const WeatherIcon(condition: 'cloudy', size: 100),
                  ],
                )
              // Layout portrait (Column) - base del PDF adaptada con los nuevos widgets
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // AGREGADO: TemperatureCard en lugar de Text sueltos
                    TemperatureCard(temperature: '24°C', city: 'Santiago de Querétaro'),
                    const SizedBox(height: 32),
                    // AGREGADO: WeatherIcon en lugar de Icon directo
                    const WeatherIcon(condition: 'cloudy', size: 120),
                    const SizedBox(height: 32),
                    const Text(
                      'Humedad: 65% | Viento: 12 km/h',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SearchScreen()),
                        );
                      },
                      child: const Text('Buscar Ciudades'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ),
    );
  }
}