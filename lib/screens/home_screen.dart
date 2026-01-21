import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reporte.dart';
import '../services/reporte_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _reporteService = ReporteService();
  final _authService = AuthService();
  List<Reporte> _reportes = [];
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() => _isLoading = true);
    
    try {
      final reportes = await _reporteService.obtenerMisReportes();
      setState(() => _reportes = reportes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reportes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        // Ya estamos en Home
        break;
      case 1:
        Navigator.of(context).pushNamed('/map');
        break;
      case 2:
        Navigator.of(context).pushNamed('/create-report').then((_) => _cargarReportes());
        break;
      case 3:
        Navigator.of(context).pushNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReportes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _cargarReportes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reportes.length,
                    itemBuilder: (context, index) {
                      return _buildReporteCard(_reportes[index]);
                    },
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Crear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes reportes',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primer reporte para empezar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context)
                  .pushNamed('/create-report')
                  .then((_) => _cargarReportes());
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear Reporte'),
          ),
        ],
      ),
    );
  }

  Widget _buildReporteCard(Reporte reporte) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    Color estadoColor;
    IconData estadoIcon;
    
    switch (reporte.estado) {
      case EstadoReporte.pendiente:
        estadoColor = Colors.orange;
        estadoIcon = Icons.pending;
        break;
      case EstadoReporte.en_proceso:
        estadoColor = Colors.blue;
        estadoIcon = Icons.autorenew;
        break;
      case EstadoReporte.resuelto:
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .pushNamed('/report-detail', arguments: reporte.id)
              .then((_) => _cargarReportes());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen (si existe)
            if (reporte.fotoUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  reporte.fotoUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50),
                    );
                  },
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y estado
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reporte.titulo,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: estadoColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              estadoIcon,
                              size: 16,
                              color: estadoColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              reporte.estado.displayName,
                              style: TextStyle(
                                color: estadoColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Categoría
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reporte.categoria.displayName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Descripción
                  Text(
                    reporte.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Fecha
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(reporte.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
