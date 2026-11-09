import '../../core/constants/categories.dart';

/// Modelo de datos para un artículo en la lista de compras.
///
/// Representa un producto con precio en USD, cantidad,
/// categoría y estado de compra.
class ItemModel {
  final String id;
  final String presupuestoId;
  final String nombre;
  final double precioUsd;
  final int cantidad;
  final ProductCategory categoria;
  final bool comprado;

  const ItemModel({
    required this.id,
    this.presupuestoId = 'default',
    required this.nombre,
    required this.precioUsd,
    required this.cantidad,
    required this.categoria,
    this.comprado = false,
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Subtotal en USD para este artículo.
  double get subtotalUsd => precioUsd * cantidad;

  // ── Serialización DB ──────────────────────────────────────────────────────

  /// Convierte a Map para insertar/actualizar en SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'presupuestoId': presupuestoId,
      'nombre': nombre,
      'precioUsd': precioUsd,
      'cantidad': cantidad,
      'categoria': categoria.name,
      'comprado': comprado ? 1 : 0,
    };
  }

  /// Crea un [ItemModel] a partir de un Map de SQLite.
  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: (map['id'] as String?) ?? '',
      presupuestoId: (map['presupuestoId'] as String?) ?? 'default',
      nombre: (map['nombre'] as String?) ?? '',
      precioUsd: (map['precioUsd'] as num?)?.toDouble() ?? 0.0,
      cantidad: (map['cantidad'] as num?)?.toInt() ?? 1,
      categoria: Categories.fromString((map['categoria'] as String?) ?? 'otros'),
      comprado: (map['comprado'] as num?)?.toInt() == 1,
    );
  }

  // ── Immutable Update ──────────────────────────────────────────────────────

  ItemModel copyWith({
    String? id,
    String? presupuestoId,
    String? nombre,
    double? precioUsd,
    int? cantidad,
    ProductCategory? categoria,
    bool? comprado,
  }) {
    return ItemModel(
      id: id ?? this.id,
      presupuestoId: presupuestoId ?? this.presupuestoId,
      nombre: nombre ?? this.nombre,
      precioUsd: precioUsd ?? this.precioUsd,
      cantidad: cantidad ?? this.cantidad,
      categoria: categoria ?? this.categoria,
      comprado: comprado ?? this.comprado,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ItemModel(id: $id, presupuestoId: $presupuestoId, nombre: $nombre, precio: \$$precioUsd, '
      'cantidad: $cantidad, categoria: ${categoria.name}, comprado: $comprado)';
}

