import 'package:flutter/material.dart';
import 'detail_screen.dart';
import '../widgets/weather_icon.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Base del PDF: lista de ciudades
  // AGREGADO: mapa con temperatura y condición por ciudad (el PDF pone '24°C' fijo para todas)
  final List<Map<String, dynamic>> cities = [
    {'name': 'Santiago', 'temp': '24°C', 'condition': 'sunny'},
    {'name': 'Querétaro', 'temp': '22°C', 'condition': 'cloudy'},
    {'name': 'México', 'temp': '20°C', 'condition': 'rainy'},
    {'name': 'Guadalajara', 'temp': '26°C', 'condition': 'sunny'},
    {'name': 'Monterrey', 'temp': '30°C', 'condition': 'sunny'},
  ];

  List<Map<String, dynamic>> filtered = [];

  // Del PDF: lógica de filtro (adaptada a Map)
  void filterCities(String query) {
    setState(() {
      filtered = cities
          .where((c) =>
              (c['name'] as String).toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayList = filtered.isEmpty ? cities : filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Ciudades'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Del PDF: TextField con filtro
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: filterCities,
              decoration: const InputDecoration(
                hintText: 'Busca una ciudad...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search), // AGREGADO: ícono en el campo
              ),
            ),
          ),
          // Del PDF: ListView con ciudades
          Expanded(
            child: ListView.builder(
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final city = displayList[index];
                return ListTile(
                  // AGREGADO: WeatherIcon mini en lugar de emoji
                  leading: WeatherIcon(
                      condition: city['condition'] as String, size: 32),
                  title: Text(
                    city['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // AGREGADO: temperatura diferente por ciudad
                  trailing: Text(
                    city['temp'] as String,
                    style: const TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          city: city['name'] as String,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Del PDF: botón Atrás
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Atrás'),
            ),
          ),
        ],
      ),
    );
  }
}