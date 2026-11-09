import '../../providers/budget_provider.dart';

/// Modelo de datos para un presupuesto individual (e.g. Mercado, Viaje, Estudios, etc.).
class BudgetModel {
  final String id;
  final String nombre;
  final TipoPresupuesto tipo;
  final double montoMaxUsd;
  final String descripcion;
  final DateTime fechaCreacion;

  const BudgetModel({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.montoMaxUsd,
    this.descripcion = '',
    required this.fechaCreacion,
  });

  /// Convierte a Map para persistencia en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo.name,
      'montoMaxUsd': montoMaxUsd,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  /// Crea un [BudgetModel] desde un Map de SQLite.
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: (map['id'] as String?) ?? 'default',
      nombre: (map['nombre'] as String?) ?? 'Presupuesto',
      tipo: TipoPresupuesto.values.firstWhere(
        (t) => t.name == map['tipo'],
        orElse: () => TipoPresupuesto.listaMercado,
      ),
      montoMaxUsd: (map['montoMaxUsd'] as num?)?.toDouble() ?? 0.0,
      descripcion: (map['descripcion'] as String?) ?? '',
      fechaCreacion: DateTime.tryParse(map['fechaCreacion'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? nombre,
    TipoPresupuesto? tipo,
    double? montoMaxUsd,
    String? descripcion,
    DateTime? fechaCreacion,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      montoMaxUsd: montoMaxUsd ?? this.montoMaxUsd,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}

