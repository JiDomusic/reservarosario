class Review {
  final String? id;
  final int rating;
  final String comentario;
  final String usuarioId;
  final String reservaId;
  final bool verificado;
  final DateTime fecha;
  final String? usuarioNombre;
  final String? mesaNumero;

  Review({
    this.id,
    required this.rating,
    required this.comentario,
    required this.usuarioId,
    required this.reservaId,
    this.verificado = false,
    required this.fecha,
    this.usuarioNombre,
    this.mesaNumero,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString(),
      rating: json['rating'] ?? 0,
      comentario: json['comentario'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      reservaId: json['reserva_id'] ?? '',
      verificado: json['verificado'] ?? false,
      fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      usuarioNombre: json['usuario_nombre'],
      mesaNumero: json['mesa_numero'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'comentario': comentario,
      'usuario_id': usuarioId,
      'reserva_id': reservaId,
      'verificado': verificado,
      'fecha': fecha.toIso8601String(),
      'usuario_nombre': usuarioNombre,
      'mesa_numero': mesaNumero,
    };
  }

  Review copyWith({
    String? id,
    int? rating,
    String? comentario,
    String? usuarioId,
    String? reservaId,
    bool? verificado,
    DateTime? fecha,
    String? usuarioNombre,
    String? mesaNumero,
  }) {
    return Review(
      id: id ?? this.id,
      rating: rating ?? this.rating,
      comentario: comentario ?? this.comentario,
      usuarioId: usuarioId ?? this.usuarioId,
      reservaId: reservaId ?? this.reservaId,
      verificado: verificado ?? this.verificado,
      fecha: fecha ?? this.fecha,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      mesaNumero: mesaNumero ?? this.mesaNumero,
    );
  }
}