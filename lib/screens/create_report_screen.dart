import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/reporte.dart';
import '../services/reporte_service.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _reporteService = ReporteService();
  final _imagePicker = ImagePicker();
  final MapController _mapController = MapController();
  
  CategoriaReporte? _categoriaSeleccionada;
  File? _imagenSeleccionada;
  LatLng? _ubicacionSeleccionada;
  LatLng _currentPosition = const LatLng(14.6349, -90.5069); // Guatemala City por defecto
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied && 
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _ubicacionSeleccionada = _currentPosition;
        });
        _mapController.move(_currentPosition, 15.0);
      }
    } catch (e) {
      debugPrint('Error al obtener ubicación: $e');
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? foto = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (foto != null) {
        setState(() {
          _imagenSeleccionada = File(foto.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al tomar foto: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _seleccionarDeGaleria() async {
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = File(imagen.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _tomarFoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarDeGaleria();
              },
            ),
            if (_imagenSeleccionada != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar imagen'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagenSeleccionada = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _crearReporte() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una categoría'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_ubicacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una ubicación en el mapa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _reporteService.crearReporte(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        categoria: _categoriaSeleccionada!,
        latitud: _ubicacionSeleccionada!.latitude,
        longitud: _ubicacionSeleccionada!.longitude,
        imagen: _imagenSeleccionada,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear reporte: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Reporte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagen
              GestureDetector(
                onTap: _mostrarOpcionesImagen,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _imagenSeleccionada != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imagenSeleccionada!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca para agregar foto',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título del reporte',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un título';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Categoría
              DropdownButtonFormField<CategoriaReporte>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: CategoriaReporte.values.map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _categoriaSeleccionada = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Por favor selecciona una categoría';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Descripción
              TextFormField(
                controller: _descripcionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descripción del problema',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  if (value.length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Mapa
              Text(
                'Ubicación del problema',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Toca en el mapa para seleccionar la ubicación exacta',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              
              const SizedBox(height: 12),
              
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition,
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        setState(() => _ubicacionSeleccionada = point);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.prueba_moviles',
                      ),
                      
                      // Marcador de ubicación seleccionada
                      if (_ubicacionSeleccionada != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _ubicacionSeleccionada!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botón de ubicación actual
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _ubicacionSeleccionada = _currentPosition);
                  _mapController.move(_currentPosition, 15.0);
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Usar mi ubicación actual'),
              ),
              
              const SizedBox(height: 24),
              
              // Botón de crear
              ElevatedButton(
                onPressed: _isLoading ? null : _crearReporte,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Crear Reporte',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
