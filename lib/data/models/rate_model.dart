/// Modelo de datos para una tasa de cambio Bs./USD.
///
/// Permite guardar múltiples tasas históricas en SQLite
/// y marcar cuál está activa actualmente.
class RateModel {
  final int? id;
  final double tasaBsUsd;
  final DateTime fechaRegistro;
  final String? fuente; // e.g. "BCV", "Paralelo", "Manual"
  final bool esActiva;

  const RateModel({
    this.id,
    required this.tasaBsUsd,
    required this.fechaRegistro,
    this.fuente,
    this.esActiva = false,
  });

  // ── Serialización DB ──────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tasaBsUsd': tasaBsUsd,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'fuente': fuente ?? 'Manual',
      'esActiva': esActiva ? 1 : 0,
    };
  }

  factory RateModel.fromMap(Map<String, dynamic> map) {
    return RateModel(
      id: (map['id'] as num?)?.toInt(),
      tasaBsUsd: (map['tasaBsUsd'] as num?)?.toDouble() ?? 896.12,
      fechaRegistro: DateTime.tryParse(map['fechaRegistro'] as String? ?? '') ??
          DateTime.now(),
      fuente: map['fuente'] as String?,
      esActiva: (map['esActiva'] as num?)?.toInt() == 1,
    );
  }

  // ── Immutable Update ──────────────────────────────────────────────────────

  RateModel copyWith({
    int? id,
    double? tasaBsUsd,
    DateTime? fechaRegistro,
    String? fuente,
    bool? esActiva,
  }) {
    return RateModel(
      id: id ?? this.id,
      tasaBsUsd: tasaBsUsd ?? this.tasaBsUsd,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      fuente: fuente ?? this.fuente,
      esActiva: esActiva ?? this.esActiva,
    );
  }

  @override
  String toString() =>
      'RateModel(id: $id, tasa: $tasaBsUsd Bs./USD, '
      'fuente: $fuente, activa: $esActiva)';
}

