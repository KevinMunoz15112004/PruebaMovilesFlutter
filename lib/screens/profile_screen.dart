import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final _authService = AuthService();

  Future<void> _cerrarSesion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      try {
        await _authService.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _authService.getUserName() ?? 'Usuario';
    final userEmail = _authService.getUserEmail() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Nombre
          Text(
            userName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Email
          Text(
            userEmail,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          const Divider(),
          
          // Información de la cuenta
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Nombre'),
            subtitle: Text(userName),
          ),
          
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Correo electrónico'),
            subtitle: Text(userEmail),
          ),
          
          const Divider(),
          
          const SizedBox(height: 16),
          
          // Información de la app
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Acerca de',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versión de la app'),
            subtitle: const Text('1.0.0'),
          ),
          
          ListTile(
            leading: const Icon(Icons.location_city),
            title: const Text('UrbanReport'),
            subtitle: const Text('Sistema de Reporte Ciudadano'),
          ),
          
          const SizedBox(height: 32),
          
          // Botón de cerrar sesión
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () => _cerrarSesion(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
