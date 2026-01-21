import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/reporte.dart';
import '../services/reporte_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reporteId;

  const ReportDetailScreen({super.key, required this.reporteId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _reporteService = ReporteService();
  final _imagePicker = ImagePicker();
  
  Reporte? _reporte;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descripcionController;
  CategoriaReporte? _categoriaSeleccionada;
  EstadoReporte? _estadoSeleccionado;
  File? _nuevaImagen;

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController();
    _descripcionController = TextEditingController();
    _cargarReporte();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _cargarReporte() async {
    setState(() => _isLoading = true);
    
    try {
      final reporte = await _reporteService.obtenerReportePorId(widget.reporteId);
      setState(() {
        _reporte = reporte;
        _tituloController.text = reporte.titulo;
        _descripcionController.text = reporte.descripcion;
        _categoriaSeleccionada = reporte.categoria;
        _estadoSeleccionado = reporte.estado;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reporte: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarImagen() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      try {
        final XFile? imagen = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (imagen != null) {
          setState(() => _nuevaImagen = File(imagen.path));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _actualizarReporte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _reporteService.actualizarReporte(
        id: widget.reporteId,
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        categoria: _categoriaSeleccionada,
        estado: _estadoSeleccionado,
        nuevaImagen: _nuevaImagen,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditing = false);
        _cargarReporte();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _eliminarReporte() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reporte'),
        content: const Text('¿Estás seguro de que deseas eliminar este reporte?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      
      try {
        await _reporteService.eliminarReporte(widget.reporteId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _reporte == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Reporte'),
        actions: [
          if (!_isEditing && _reporte != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (!_isEditing && _reporte != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _eliminarReporte,
            ),
        ],
      ),
      body: _reporte == null
          ? const Center(child: Text('Reporte no encontrado'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagen
                  if (_isEditing && _nuevaImagen != null)
                    Stack(
                      children: [
                        Image.file(
                          _nuevaImagen!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            onPressed: () => setState(() => _nuevaImagen = null),
                          ),
                        ),
                      ],
                    )
                  else if (_reporte!.fotoUrl != null)
                    Image.network(
                      _reporte!.fotoUrl!,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50),
                        );
                      },
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isEditing
                        ? _buildEditForm()
                        : _buildViewMode(dateFormat),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildViewMode(DateFormat dateFormat) {
    Color estadoColor;
    IconData estadoIcon;
    
    switch (_reporte!.estado) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          _reporte!.titulo,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        
        const SizedBox(height: 16),
        
        // Estado y categoría
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(estadoIcon, size: 16, color: estadoColor),
                  const SizedBox(width: 4),
                  Text(
                    _reporte!.estado.displayName,
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _reporte!.categoria.displayName,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Descripción
        Text(
          'Descripción',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _reporte!.descripcion,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        
        const SizedBox(height: 24),
        
        // Fecha
        Row(
          children: [
            const Icon(Icons.access_time, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Creado: ${dateFormat.format(_reporte!.createdAt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Mapa
        Text(
          'Ubicación',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(_reporte!.latitud, _reporte!.longitud),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.prueba_moviles',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_reporte!.latitud, _reporte!.longitud),
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
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Botón cambiar imagen
          if (_reporte!.fotoUrl != null || _nuevaImagen != null)
            OutlinedButton.icon(
              onPressed: _seleccionarImagen,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Cambiar imagen'),
            ),
          
          const SizedBox(height: 16),
          
          // Título
          TextFormField(
            controller: _tituloController,
            decoration: const InputDecoration(
              labelText: 'Título',
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
          ),
          
          const SizedBox(height: 16),
          
          // Estado
          DropdownButtonFormField<EstadoReporte>(
            value: _estadoSeleccionado,
            decoration: const InputDecoration(
              labelText: 'Estado',
              border: OutlineInputBorder(),
            ),
            items: EstadoReporte.values.map((estado) {
              return DropdownMenuItem(
                value: estado,
                child: Text(estado.displayName),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _estadoSeleccionado = value);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Descripción
          TextFormField(
            controller: _descripcionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa una descripción';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _tituloController.text = _reporte!.titulo;
                      _descripcionController.text = _reporte!.descripcion;
                      _categoriaSeleccionada = _reporte!.categoria;
                      _estadoSeleccionado = _reporte!.estado;
                      _nuevaImagen = null;
                    });
                  },
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _actualizarReporte,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
