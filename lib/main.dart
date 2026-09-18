// Arranque de la aplicación: tema, controlador y primera pantalla.

import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'state/tag_controller.dart';

/// Punto de entrada de la aplicación.
void main() {
  runApp(NfcReaderApp());
}

/// Raíz de la aplicación: tema y pantalla de bienvenida.
class NfcReaderApp extends StatelessWidget {
  NfcReaderApp({super.key});

  final TagController _controller = TagController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SUS NFC Tag Editor',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: WelcomeScreen(controller: _controller),
    );
  }
}
