import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Climate App',
      debugShowCheckedModeBanner: false, // Quita la molesta etiqueta de "Debug"
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clima Actual'),
        centerTitle: true,
        backgroundColor: Colors.red.withOpacity(0.1),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono del clima
            const Icon(
              Icons.sunny,
              size: 120,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            
            const Text(
              '28°C',
              style: TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            
            // Ubicación
            const Text(
              'Querétaro',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}