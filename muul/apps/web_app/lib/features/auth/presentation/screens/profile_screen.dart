import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../state/auth_controller.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  static const path = '/profile';

  final AuthController controller;

  Future<void> _logout(BuildContext context) async {
    await controller.logout();
    if (!context.mounted) {
      return;
    }
    context.go(LoginScreen.path);
  }

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay sesion activa.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de usuario'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${user.displayName}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Correo: ${user.email}'),
            const SizedBox(height: 8),
            Text('Idioma preferido: ${user.preferredLanguage.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Bio: ${user.bio?.isEmpty == false ? user.bio : 'Sin bio'}'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => context.go(EditProfileScreen.path),
              child: const Text('Editar perfil'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.go('/workspace'),
              child: const Text('Ir al espacio protegido'),
            ),
          ],
        ),
      ),
    );
  }
}
