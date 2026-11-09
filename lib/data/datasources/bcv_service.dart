import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Resultado de la consulta de tasa de cambio.
class LiveRateResult {
  final double rate;
  final String fuente;
  final DateTime? fechaActualizacion;
  final bool isSuccess;
  final String? errorMessage;

  const LiveRateResult({
    required this.rate,
    required this.fuente,
    this.fechaActualizacion,
    required this.isSuccess,
    this.errorMessage,
  });
}

/// Servicio para consultar la tasa oficial del Banco Central de Venezuela (BCV)
/// y el mercado paralelo en tiempo real.
class BcvService {
  BcvService._();

  static const String _bcvApiUrl = 'https://ve.dolarapi.com/v1/dolares/oficial';
  static const String _paraleloApiUrl =
      'https://ve.dolarapi.com/v1/dolares/paralelo';

  /// Obtiene la tasa oficial del BCV (promedio ponderado del sistema bancario).
  static Future<LiveRateResult> fetchBcvRate() async {
    try {
      final response = await http
          .get(Uri.parse(_bcvApiUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final promedio = (data['promedio'] as num?)?.toDouble();

        if (promedio != null && promedio > 0) {
          DateTime? fecha;
          if (data['fechaActualizacion'] != null) {
            fecha = DateTime.tryParse(data['fechaActualizacion'] as String);
          }

          return LiveRateResult(
            rate: promedio,
            fuente: 'BCV',
            fechaActualizacion: fecha,
            isSuccess: true,
          );
        }
      }
      return const LiveRateResult(
        rate: 0.0,
        fuente: 'BCV',
        isSuccess: false,
        errorMessage: 'Respuesta inválida del servidor BCV.',
      );
    } catch (e) {
      debugPrint('[BcvService] Error consultando BCV: $e');
      return LiveRateResult(
        rate: 0.0,
        fuente: 'BCV',
        isSuccess: false,
        errorMessage: 'No se pudo conectar con el BCV (sin internet o timeout).',
      );
    }
  }

  /// Consulta todas las cotizaciones de Venezuela (BCV y Paralelo) en una sola llamada.
  static Future<List<LiveRateResult>> fetchAllDolares() async {
    try {
      final response = await http
          .get(Uri.parse('https://ve.dolarapi.com/v1/dolares'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        final results = <LiveRateResult>[];

        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final promedio = (map['promedio'] as num?)?.toDouble() ?? 0.0;
          final fuente = (map['fuente'] as String? ?? '').toLowerCase();
          final isBcv = fuente == 'oficial';
          DateTime? fecha;
          if (map['fechaActualizacion'] != null) {
            fecha = DateTime.tryParse(map['fechaActualizacion'] as String);
          }

          results.add(LiveRateResult(
            rate: promedio,
            fuente: isBcv ? 'BCV' : 'Paralelo',
            fechaActualizacion: fecha,
            isSuccess: true,
          ));
        }

        return results;
      }
      return [];
    } catch (e) {
      debugPrint('[BcvService] Error consultando dolares: $e');
      return [];
    }
  }
  static Future<LiveRateResult> fetchParaleloRate() async {
    try {
      final response = await http
          .get(Uri.parse(_paraleloApiUrl))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final promedio = (data['promedio'] as num?)?.toDouble();

        if (promedio != null && promedio > 0) {
          DateTime? fecha;
          if (data['fechaActualizacion'] != null) {
            fecha = DateTime.tryParse(data['fechaActualizacion'] as String);
          }

          return LiveRateResult(
            rate: promedio,
            fuente: 'Paralelo',
            fechaActualizacion: fecha,
            isSuccess: true,
          );
        }
      }
      return const LiveRateResult(
        rate: 0.0,
        fuente: 'Paralelo',
        isSuccess: false,
        errorMessage: 'Respuesta inválida del servidor paralelo.',
      );
    } catch (e) {
      debugPrint('[BcvService] Error consultando Paralelo: $e');
      return LiveRateResult(
        rate: 0.0,
        fuente: 'Paralelo',
        isSuccess: false,
        errorMessage: 'No se pudo consultar la tasa paralela.',
      );
    }
  }
}

