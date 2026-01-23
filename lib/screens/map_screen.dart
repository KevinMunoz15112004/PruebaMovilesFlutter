import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/reporte.dart';
import '../services/reporte_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _reporteService = ReporteService();
  final MapController _mapController = MapController();
  List<Reporte> _reportes = [];
  bool _isLoading = false;
  LatLng _currentPosition = const LatLng(14.6349, -90.5069);

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
    _cargarReportes();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Los permisos de ubicación están deshabilitados permanentemente'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        return;
      }

      // Obtener ubicación
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      // Centrar el mapa en la ubicación actual
      _mapController.move(_currentPosition, 13.0);
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
    }
  }

  Future<void> _cargarReportes() async {
    setState(() => _isLoading = true);
    
    try {
      final reportes = await _reporteService.obtenerReportesNoResueltos();
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

  Color _getCategoryColor(CategoriaReporte categoria) {
    switch (categoria) {
      case CategoriaReporte.bache:
        return Colors.red;
      case CategoriaReporte.luminaria:
        return Colors.yellow;
      case CategoriaReporte.basura:
        return Colors.green;
      case CategoriaReporte.alcantarilla:
        return Colors.blue;
      case CategoriaReporte.otro:
        return Colors.purple;
    }
  }

  void _mostrarDetalleReporte(Reporte reporte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              if (reporte.fotoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    reporte.fotoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              
              if (reporte.fotoUrl != null) const SizedBox(height: 16),
              
              Text(
                reporte.titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              const SizedBox(height: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor(reporte.categoria).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  reporte.categoria.displayName,
                  style: TextStyle(
                    color: _getCategoryColor(reporte.categoria),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                reporte.descripcion,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Estado: ${reporte.estado.displayName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Reportes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _obtenerUbicacionActual,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReportes,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.prueba_moviles',
              ),
              
              // Marcadores de reportes
              MarkerLayer(
                markers: _reportes.map((reporte) {
                  return Marker(
                    point: LatLng(reporte.latitud, reporte.longitud),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => _mostrarDetalleReporte(reporte),
                      child: Icon(
                        Icons.location_on,
                        color: _getCategoryColor(reporte.categoria),
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Marcador de ubicación actual
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition,
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.my_location,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Indicador de carga
          if (_isLoading)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Cargando reportes...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Leyenda
          Positioned(
            bottom: 20,
            left: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Leyenda',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(Colors.red, 'Bache'),
                    _buildLegendItem(Colors.yellow, 'Luminaria'),
                    _buildLegendItem(Colors.green, 'Basura'),
                    _buildLegendItem(Colors.blue, 'Alcantarilla'),
                    _buildLegendItem(Colors.purple, 'Otro'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
