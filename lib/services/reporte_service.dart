import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reporte.dart';
import '../config/supabase_config.dart';

class ReporteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Reporte> crearReporte({
    required String titulo,
    required String descripcion,
    required CategoriaReporte categoria,
    required double latitud,
    required double longitud,
    File? imagen,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    String? fotoUrl;

    if (imagen != null) {
      fotoUrl = await _subirImagen(imagen);
    }

    final data = {
      'usuario_id': userId,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria.toString().split('.').last,
      'estado': 'pendiente',
      'latitud': latitud,
      'longitud': longitud,
      'foto_url': fotoUrl,
    };

    final response = await _supabase
        .from('reportes')
        .insert(data)
        .select()
        .single();

    return Reporte.fromJson(response);
  }

  Future<List<Reporte>> obtenerMisReportes() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('reportes')
        .select()
        .eq('usuario_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Reporte.fromJson(json)).toList();
  }

  Future<List<Reporte>> obtenerReportesNoResueltos() async {
    final response = await _supabase
        .from('reportes')
        .select()
        .neq('estado', 'resuelto')
        .order('created_at', ascending: false);

    return (response as List).map((json) => Reporte.fromJson(json)).toList();
  }

  Future<Reporte> obtenerReportePorId(String id) async {
    final response = await _supabase
        .from('reportes')
        .select()
        .eq('id', id)
        .single();

    return Reporte.fromJson(response);
  }

  Future<Reporte> actualizarReporte({
    required String id,
    String? titulo,
    String? descripcion,
    CategoriaReporte? categoria,
    EstadoReporte? estado,
    double? latitud,
    double? longitud,
    File? nuevaImagen,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final Map<String, dynamic> updates = {};

    if (titulo != null) updates['titulo'] = titulo;
    if (descripcion != null) updates['descripcion'] = descripcion;
    if (categoria != null) {
      updates['categoria'] = categoria.toString().split('.').last;
    }
    if (estado != null) {
      updates['estado'] = estado.toString().split('.').last;
    }
    if (latitud != null) updates['latitud'] = latitud;
    if (longitud != null) updates['longitud'] = longitud;

    if (nuevaImagen != null) {
      final fotoUrl = await _subirImagen(nuevaImagen);
      updates['foto_url'] = fotoUrl;
    }

    final response = await _supabase
        .from('reportes')
        .update(updates)
        .eq('id', id)
        .eq('usuario_id', userId)
        .select()
        .single();

    return Reporte.fromJson(response);
  }

  Future<void> eliminarReporte(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    await _supabase
        .from('reportes')
        .delete()
        .eq('id', id)
        .eq('usuario_id', userId);
  }

  Future<String> _subirImagen(File imagen) async {
    final userId = _supabase.auth.currentUser?.id;
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    await _supabase.storage
        .from(SupabaseConfig.imagesBucket)
        .upload(fileName, imagen);

    final publicUrl = _supabase.storage
        .from(SupabaseConfig.imagesBucket)
        .getPublicUrl(fileName);

    return publicUrl;
  }
}
