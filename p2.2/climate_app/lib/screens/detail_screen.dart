import 'package:flutter/material.dart';
import '../widgets/weather_icon.dart';
import '../widgets/temperature_card.dart';

class DetailScreen extends StatelessWidget {
  final String city;
  const DetailScreen({Key? key, required this.city}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> forecast = [
      {'day': 'Lun', 'temp': '24°C', 'condition': 'sunny'},
      {'day': 'Mar', 'temp': '26°C', 'condition': 'sunny'},
      {'day': 'Mié', 'temp': '20°C', 'condition': 'rainy'},
      {'day': 'Jue', 'temp': '25°C', 'condition': 'cloudy'},
      {'day': 'Vie', 'temp': '28°C', 'condition': 'sunny'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('$city - 5 Días'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      // FIX: SingleChildScrollView evita el overflow en landscape
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TemperatureCard(temperature: '24°C', city: city),
            const SizedBox(height: 24),
            const Text(
              'Pronóstico 5 días',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // shrinkWrap + NeverScrollableScrollPhysics para usar dentro de SingleChildScrollView
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: forecast.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final day = forecast[index];
                return ListTile(
                  leading: WeatherIcon(condition: day['condition']!, size: 36),
                  title: Text(
                    day['day']!,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  trailing: Text(
                    day['temp']!,
                    style: const TextStyle(
                        fontSize: 22, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}