import 'package:flutter/material.dart';

/// WeatherIcon — componente reutilizable pedido en la práctica.
///
/// DEL PDF: estructura base de la clase y el parámetro [condition].
/// AGREGADO: parámetro [size], condiciones 'rainy', 'cloudy', 'snowy', 'stormy',
/// colores por condición y el factory-style switch para mapear condición → ícono.
class WeatherIcon extends StatelessWidget {
  final String condition; // 'sunny' | 'cloudy' | 'rainy' | 'snowy' | 'stormy'
  final double size;      // AGREGADO: tamaño configurable

  const WeatherIcon({
    Key? key,
    required this.condition,
    this.size = 80,       // valor por defecto del PDF
  }) : super(key: key);

  // AGREGADO: mapeo de condición a ícono y color
  IconData get _icon {
    switch (condition) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'rainy':
        return Icons.grain;
      case 'snowy':
        return Icons.ac_unit;
      case 'stormy':
        return Icons.thunderstorm;
      case 'cloudy':
      default:
        return Icons.cloud; // Del PDF: Icons.cloud como fallback
    }
  }

  Color get _color {
    switch (condition) {
      case 'sunny':
        return Colors.orange;
      case 'rainy':
        return Colors.indigo;
      case 'snowy':
        return Colors.lightBlue;
      case 'stormy':
        return Colors.deepPurple;
      case 'cloudy':
      default:
        return Colors.blue; // Del PDF: Colors.blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _icon,
      size: size,
      color: _color,
    );
  }
}