import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/categories.dart';
import '../../data/models/item_model.dart';
import 'currency_format.dart';

/// Servicio para compartir la lista de compras por WhatsApp u otras apps.
///
/// Genera texto enriquecido con emojis, agrupado por categoría,
/// con subtotales, total en USD y equivalente en Bs.
class ShareService {
  ShareService._();

  /// Genera y abre el diálogo del sistema para compartir la lista.
  ///
  /// En web o escritorio (Windows/Linux) copia el texto
  /// al portapapeles y retorna true. En móviles abre el menú del sistema.
  static Future<bool> compartirLista({
    required List<ItemModel> items,
    required double tasaBsUsd,
    double presupuestoMaxUsd = 0,
    String titulo = 'LISTA DE COMPRAS',
  }) async {
    final texto = _buildText(
      items: items,
      tasaBsUsd: tasaBsUsd,
      presupuestoMaxUsd: presupuestoMaxUsd,
      titulo: titulo,
    );

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
      await Clipboard.setData(ClipboardData(text: texto));
      return true; // Copiado al portapapeles
    } else {
      try {
        await Share.share(
          texto,
          subject: '🛒 $titulo — PresuCompra',
        );
        return false;
      } catch (_) {
        await Clipboard.setData(ClipboardData(text: texto));
        return true;
      }
    }
  }

  // ── Construcción del texto ──────────────────────────────────────────────────

  static String _buildText({
    required List<ItemModel> items,
    required double tasaBsUsd,
    required double presupuestoMaxUsd,
    String titulo = 'LISTA DE COMPRAS',
  }) {
    final buffer = StringBuffer();
    final dt = DateTime.now();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final now = '$d/$m/${dt.year} $h:$min';

    // ── Encabezado ────────────────────────────────────────────────────────────
    buffer.writeln('*${titulo.toUpperCase()} — PRESUCOMPRA*');
    buffer.writeln('📅 $now');
    buffer.writeln('💱 Tasa: ${CurrencyFormat.formatBs(tasaBsUsd)} Bs./USD');
    buffer.writeln('─────────────────────────');

    if (items.isEmpty) {
      buffer.writeln('\n_(Lista vacía)_');
      return buffer.toString();
    }

    // ── Artículos agrupados por categoría ─────────────────────────────────────
    final pendientes = items.where((i) => !i.comprado).toList();
    final comprados = items.where((i) => i.comprado).toList();

    // Agrupar pendientes por categoría
    final porCategoria = <ProductCategory, List<ItemModel>>{};
    for (final item in pendientes) {
      porCategoria.putIfAbsent(item.categoria, () => []).add(item);
    }

    for (final entry in porCategoria.entries) {
      final meta = Categories.metaOf(entry.key);
      buffer.writeln('\n${meta.emoji} *${meta.label.toUpperCase()}*');

      for (final item in entry.value) {
        final subtotal = item.subtotalUsd;
        buffer.writeln(
          '  • ${item.nombre} '
          '(${item.cantidad} × ${CurrencyFormat.formatUsd(item.precioUsd)}) '
          '= *${CurrencyFormat.formatUsd(subtotal)}*',
        );
      }
    }

    // ── Artículos ya comprados ────────────────────────────────────────────────
    if (comprados.isNotEmpty) {
      buffer.writeln('\n✅ *YA EN EL CARRITO*');
      for (final item in comprados) {
        buffer.writeln(
          '  ✔ ~${item.nombre}~ '
          '(${item.cantidad} × ${CurrencyFormat.formatUsd(item.precioUsd)})',
        );
      }
    }

    // ── Totales ───────────────────────────────────────────────────────────────
    final totalUsd = items.fold(0.0, (sum, i) => sum + i.subtotalUsd);
    final totalBs = totalUsd * tasaBsUsd;
    final totalCompradoUsd =
        comprados.fold(0.0, (sum, i) => sum + i.subtotalUsd);
    final totalPendienteUsd = totalUsd - totalCompradoUsd;

    buffer.writeln('\n─────────────────────────');
    buffer.writeln('📊 *RESUMEN*');
    buffer.writeln(
        '  Artículos: ${items.length} (${pendientes.length} pendientes)');
    buffer.writeln('  Comprado:  ${CurrencyFormat.formatUsd(totalCompradoUsd)}');
    buffer.writeln('  Pendiente: ${CurrencyFormat.formatUsd(totalPendienteUsd)}');
    buffer.writeln('─────────────────────────');
    buffer.writeln('💵 *TOTAL: ${CurrencyFormat.formatUsd(totalUsd)}*');
    buffer.writeln('🇻🇪 *Equivalente: ${CurrencyFormat.formatBs(totalBs)} Bs.*');

    if (presupuestoMaxUsd > 0) {
      final restante = presupuestoMaxUsd - totalUsd;
      final pct = ((totalUsd / presupuestoMaxUsd) * 100).toStringAsFixed(1);
      final emoji = restante >= 0 ? '🟢' : '🔴';
      buffer.writeln(
        '$emoji Presupuesto: ${CurrencyFormat.formatUsd(presupuestoMaxUsd)} '
        '($pct% usado)',
      );
      if (restante < 0) {
        buffer.writeln('⚠️ Excedido: ${CurrencyFormat.formatUsd(restante.abs())}');
      } else {
        buffer.writeln('✅ Disponible: ${CurrencyFormat.formatUsd(restante)}');
      }
    }

    buffer.writeln('\n_Generado con PresuCompra_ 🛒');

    return buffer.toString();
  }
}

