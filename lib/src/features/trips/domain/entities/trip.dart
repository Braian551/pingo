/// Entidad de Dominio: Trip (Viaje)
/// 
/// Representa un viaje dentro de la aplicaciÃ³n Ping Go.
/// Esta es una entidad inmutable del dominio (PURA lÃ³gica de negocio).
class Trip {
  final int id;
  final int usuarioId;
  final int? conductorId;
  final TripType tipoServicio;
  final TripStatus estado;
  final TripLocation origen;
  final TripLocation destino;
  final double? precioEstimado;
  final double? precioFinal;
  final double? distanciaKm;
  final int? duracionEstimadaMinutos;
  final DateTime fechaSolicitud;
  final DateTime? fechaAceptacion;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? calificacionConductor;
  final int? calificacionUsuario;
  final String? comentarioConductor;
  final String? comentarioUsuario;
  final String? motivoCancelacion;

  const Trip({
    required this.id,
    required this.usuarioId,
    this.conductorId,
    required this.tipoServicio,
    required this.estado,
    required this.origen,
    required this.destino,
    this.precioEstimado,
    this.precioFinal,
    this.distanciaKm,
    this.duracionEstimadaMinutos,
    required this.fechaSolicitud,
    this.fechaAceptacion,
    this.fechaInicio,
    this.fechaFin,
    this.calificacionConductor,
    this.calificacionUsuario,
    this.comentarioConductor,
    this.comentarioUsuario,
    this.motivoCancelacion,
  });

  /// LÃ³gica de negocio: Â¿El viaje estÃ¡ activo?
  bool get isActive =>
      estado == TripStatus.pendiente ||
      estado == TripStatus.aceptado ||
      estado == TripStatus.enCurso;

  /// LÃ³gica de negocio: Â¿El viaje estÃ¡ completado?
  bool get isCompleted => estado == TripStatus.completado;

  /// LÃ³gica de negocio: Â¿El viaje estÃ¡ cancelado?
  bool get isCancelled => estado == TripStatus.cancelado;

  /// LÃ³gica de negocio: Â¿Tiene conductor asignado?
  bool get hasConductor => conductorId != null && conductorId! > 0;

  /// LÃ³gica de negocio: DuraciÃ³n real del viaje
  int? get duracionRealMinutos {
    if (fechaInicio == null || fechaFin == null) return null;
    return fechaFin!.difference(fechaInicio!).inMinutes;
  }

  /// LÃ³gica de negocio: Â¿Puede ser cancelado?
  bool get canBeCancelled =>
      estado == TripStatus.pendiente ||
      estado == TripStatus.aceptado;

  /// LÃ³gica de negocio: Â¿Puede ser calificado?
  bool get canBeRated => estado == TripStatus.completado;

  /// CopyWith para inmutabilidad
  Trip copyWith({
    int? id,
    int? usuarioId,
    int? conductorId,
    TripType? tipoServicio,
    TripStatus? estado,
    TripLocation? origen,
    TripLocation? destino,
    double? precioEstimado,
    double? precioFinal,
    double? distanciaKm,
    int? duracionEstimadaMinutos,
    DateTime? fechaSolicitud,
    DateTime? fechaAceptacion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    int? calificacionConductor,
    int? calificacionUsuario,
    String? comentarioConductor,
    String? comentarioUsuario,
    String? motivoCancelacion,
  }) {
    return Trip(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      conductorId: conductorId ?? this.conductorId,
      tipoServicio: tipoServicio ?? this.tipoServicio,
      estado: estado ?? this.estado,
      origen: origen ?? this.origen,
      destino: destino ?? this.destino,
      precioEstimado: precioEstimado ?? this.precioEstimado,
      precioFinal: precioFinal ?? this.precioFinal,
      distanciaKm: distanciaKm ?? this.distanciaKm,
      duracionEstimadaMinutos:
          duracionEstimadaMinutos ?? this.duracionEstimadaMinutos,
      fechaSolicitud: fechaSolicitud ?? this.fechaSolicitud,
      fechaAceptacion: fechaAceptacion ?? this.fechaAceptacion,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      calificacionConductor: calificacionConductor ?? this.calificacionConductor,
      calificacionUsuario: calificacionUsuario ?? this.calificacionUsuario,
      comentarioConductor: comentarioConductor ?? this.comentarioConductor,
      comentarioUsuario: comentarioUsuario ?? this.comentarioUsuario,
      motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
    );
  }

  @override
  String toString() => 'Trip(id: $id, estado: $estado, usuario: $usuarioId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Trip && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Tipo de servicio/viaje
enum TripType {
  motocicleta('Motocicleta'),
  auto('Auto'),
  delivery('Delivery');

  final String displayName;
  const TripType(this.displayName);

  static TripType fromString(String value) {
    return TripType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TripType.motocicleta,
    );
  }
}

/// Estado del viaje
enum TripStatus {
  pendiente('Pendiente'),
  aceptado('Aceptado'),
  enCurso('En Curso'),
  completado('Completado'),
  cancelado('Cancelado');

  final String displayName;
  const TripStatus(this.displayName);

  static TripStatus fromString(String value) {
    return TripStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TripStatus.pendiente,
    );
  }
}

/// UbicaciÃ³n del viaje (origen/destino)
class TripLocation {
  final String direccion;
  final double latitud;
  final double longitud;
  final String? referencia;

  const TripLocation({
    required this.direccion,
    required this.latitud,
    required this.longitud,
    this.referencia,
  });

  @override
  String toString() => direccion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripLocation &&
          runtimeType == other.runtimeType &&
          latitud == other.latitud &&
          longitud == other.longitud;

  @override
  int get hashCode => latitud.hashCode ^ longitud.hashCode;
}
