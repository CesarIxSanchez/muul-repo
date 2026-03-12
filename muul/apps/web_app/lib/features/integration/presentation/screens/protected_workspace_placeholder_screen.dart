import 'package:flutter/material.dart';

class ProtectedWorkspacePlaceholderScreen extends StatelessWidget {
  const ProtectedWorkspacePlaceholderScreen({super.key});

  static const path = '/workspace';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espacio protegido')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Autenticacion y sesion listos.'),
            SizedBox(height: 12),
            Text('TODO(Persona 2): Reemplazar por HomeScreen y flujo de exploracion/busqueda.'),
            Text('TODO(Persona 3): Integrar MapScreen, RoutePlannerScreen y RouteDetailScreen.'),
            Text('TODO(Persona 4): Integrar flujo web de negocio y administracion de perfil comercial.'),
            Text('TODO(Persona 5): Integrar AppRouter global, achievements y localizacion compartida.'),
          ],
        ),
      ),
    );
  }
}
