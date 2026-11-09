import 'dart:convert';
import '../../providers/budget_provider.dart';

/// Modelo de datos para una compra finalizada en el historial.
class PurchaseHistoryModel {
  final String id;
  final String presupuestoId;
  final String nombrePresupuesto;
  final TipoPresupuesto tipoPresupuesto;
  final double totalUsd;
  final double totalBs;
  final double tasaBsUsd;
  final int cantidadArticulos;
  final DateTime fecha;
  final String articulosResumen;
  final List<Map<String, dynamic>> itemsSnapshot;

  const PurchaseHistoryModel({
    required this.id,
    required this.presupuestoId,
    required this.nombrePresupuesto,
    required this.tipoPresupuesto,
    required this.totalUsd,
    required this.totalBs,
    required this.tasaBsUsd,
    required this.cantidadArticulos,
    required this.fecha,
    required this.articulosResumen,
    this.itemsSnapshot = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'presupuestoId': presupuestoId,
      'nombrePresupuesto': nombrePresupuesto,
      'tipoPresupuesto': tipoPresupuesto.name,
      'totalUsd': totalUsd,
      'totalBs': totalBs,
      'tasaBsUsd': tasaBsUsd,
      'cantidadArticulos': cantidadArticulos,
      'fecha': fecha.toIso8601String(),
      'articulosResumen': articulosResumen,
      'itemsJson': json.encode(itemsSnapshot),
    };
  }

  factory PurchaseHistoryModel.fromMap(Map<String, dynamic> map) {
    List<Map<String, dynamic>> parsedSnapshot = [];
    final jsonStr = map['itemsJson'] as String?;
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = json.decode(jsonStr) as List<dynamic>;
        parsedSnapshot = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {}
    }

    return PurchaseHistoryModel(
      id: (map['id'] as String?) ?? '',
      presupuestoId: (map['presupuestoId'] as String?) ?? '',
      nombrePresupuesto: (map['nombrePresupuesto'] as String?) ?? 'Compra',
      tipoPresupuesto: TipoPresupuesto.values.firstWhere(
        (t) => t.name == map['tipoPresupuesto'],
        orElse: () => TipoPresupuesto.listaMercado,
      ),
      totalUsd: (map['totalUsd'] as num?)?.toDouble() ?? 0.0,
      totalBs: (map['totalBs'] as num?)?.toDouble() ?? 0.0,
      tasaBsUsd: (map['tasaBsUsd'] as num?)?.toDouble() ?? 1.0,
      cantidadArticulos: (map['cantidadArticulos'] as num?)?.toInt() ?? 0,
      fecha: DateTime.tryParse(map['fecha'] as String? ?? '') ?? DateTime.now(),
      articulosResumen: (map['articulosResumen'] as String?) ?? '',
      itemsSnapshot: parsedSnapshot,
    );
  }
}

