import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar ciudad por defecto al abrir
    Future.microtask(() =>
        context.read<WeatherProvider>().fetchWeather('Queretaro'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final city = _controller.text.trim();
    if (city.isNotEmpty) {
      context.read<WeatherProvider>().fetchWeather(city);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Climate App'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de busqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Buscar ciudad...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
          // Contenido dinamico
          Expanded(
            child: Consumer<WeatherProvider>(
              builder: (context, wp, _) {
                if (wp.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (wp.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(wp.error!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => wp.fetchWeather('Queretaro'),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }
                if (wp.weather == null) {
                  return const Center(child: Text('Ingresa una ciudad'));
                }
                final w = wp.weather!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(w.city,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('${w.temperature}°C',
                          style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                      Text(w.description,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _stat('Humedad', '${w.humidity}%'),
                          _stat('Viento', '${w.windSpeed} m/s'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      );
}