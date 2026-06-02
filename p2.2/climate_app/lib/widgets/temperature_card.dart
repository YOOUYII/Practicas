import 'package:flutter/material.dart';

/// TemperatureCard — componente reutilizable.
///
/// COMPLETAMENTE AGREGADO: el PDF lo menciona en la estructura de carpetas
/// ("widgets/temperature_card.dart") pero no da ningún código.
/// Muestra la temperatura grande y la ciudad en una Card con estilo visual claro.
class TemperatureCard extends StatelessWidget {
  final String temperature;
  final String city;

  const TemperatureCard({
    Key? key,
    required this.temperature,
    required this.city,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              temperature,
              // Del PDF: fontSize 72, bold, color blue
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              city,
              // Del PDF: fontSize 24 para la ciudad
              style: const TextStyle(fontSize: 24, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}