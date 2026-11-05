import 'package:flutter/material.dart';

void main() {
  runApp(const WbsPlayerApp());
}

class WbsPlayerApp extends StatelessWidget {
  const WbsPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wbs Player',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Wbs Player'))),
    );
  }
}
