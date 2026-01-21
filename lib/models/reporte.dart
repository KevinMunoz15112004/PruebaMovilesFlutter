class Reporte {
  final String id;
  final String usuarioId;
  final String titulo;
  final String descripcion;
  final CategoriaReporte categoria;
  final EstadoReporte estado;
  final double latitud;
  final double longitud;
  final String? fotoUrl;
  final DateTime createdAt;

  Reporte({
    required this.id,
    required this.usuarioId,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.estado,
    required this.latitud,
    required this.longitud,
    this.fotoUrl,
    required this.createdAt,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) {
    return Reporte(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
      categoria: CategoriaReporte.values.firstWhere(
        (e) => e.toString().split('.').last == json['categoria'],
      ),
      estado: EstadoReporte.values.firstWhere(
        (e) => e.toString().split('.').last == json['estado'],
      ),
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      fotoUrl: json['foto_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria.toString().split('.').last,
      'estado': estado.toString().split('.').last,
      'latitud': latitud,
      'longitud': longitud,
      'foto_url': fotoUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Reporte copyWith({
    String? id,
    String? usuarioId,
    String? titulo,
    String? descripcion,
    CategoriaReporte? categoria,
    EstadoReporte? estado,
    double? latitud,
    double? longitud,
    String? fotoUrl,
    DateTime? createdAt,
  }) {
    return Reporte(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      estado: estado ?? this.estado,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum CategoriaReporte {
  bache,
  luminaria,
  basura,
  alcantarilla,
  otro,
}

enum EstadoReporte {
  pendiente,
  en_proceso,
  resuelto,
}

extension CategoriaReporteExtension on CategoriaReporte {
  String get displayName {
    switch (this) {
      case CategoriaReporte.bache:
        return 'Bache';
      case CategoriaReporte.luminaria:
        return 'Luminaria dañada';
      case CategoriaReporte.basura:
        return 'Acumulación de basura';
      case CategoriaReporte.alcantarilla:
        return 'Alcantarilla obstruida';
      case CategoriaReporte.otro:
        return 'Otro';
    }
  }
}

extension EstadoReporteExtension on EstadoReporte {
  String get displayName {
    switch (this) {
      case EstadoReporte.pendiente:
        return 'Pendiente';
      case EstadoReporte.en_proceso:
        return 'En proceso';
      case EstadoReporte.resuelto:
        return 'Resuelto';
    }
  }
}
