import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/currency_format.dart';
import '../../../data/models/purchase_history_model.dart';
import '../../../providers/budget_provider.dart';

/// Modal para consultar el historial de compras finalizadas y archivadas.
class PurchaseHistoryModal extends StatelessWidget {
  const PurchaseHistoryModal({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final historial = provider.historial;

    final totalHistoricoUsd = historial.fold<double>(
      0.0,
      (sum, h) => sum + h.totalUsd,
    );
    final totalHistoricoBs = totalHistoricoUsd * provider.tasaBsUsd;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Título
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history_rounded,
                        color: AppColors.brand, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Historial de Compras',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Registro acumulado de compras finalizadas',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),

            // Resumen acumulado
            if (historial.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBase,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL HISTÓRICO GASTADO',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormat.formatUsd(totalHistoricoUsd),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${historial.length} compra${historial.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '≈ ${CurrencyFormat.formatBs(totalHistoricoBs)} Bs.',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Lista del historial
            if (historial.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          size: 48, color: AppColors.textDisabled),
                      const SizedBox(height: 12),
                      const Text(
                        'Aún no tienes compras archivadas',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cuando termines de hacer una compra, toca "Finalizar Compra"\npara guardarla aquí en tu historial.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: historial.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = historial[index];
                    return _HistoryTile(
                      compra: item,
                      onDelete: () => provider.eliminarCompraHistorial(item.id),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatefulWidget {
  final PurchaseHistoryModel compra;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.compra,
    required this.onDelete,
  });

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _expanded = false;

  String _formatFecha(DateTime d) {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${meses[d.month - 1]} ${d.year} • $hora:$min';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.compra;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brand.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                c.tipoPresupuesto.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    c.nombrePresupuesto,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  CurrencyFormat.formatUsd(c.totalUsd),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatFecha(c.fecha),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${CurrencyFormat.formatBs(c.totalBs)} Bs.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (c.articulosResumen.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${c.cantidadArticulos} arts: ${c.articulosResumen}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textDisabled,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
            ),
          ),

          // Desglose detallado expandible
          if (_expanded) ...[
            const Divider(color: AppColors.cardBorder, height: 1),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              color: AppColors.backgroundBase.withAlpha(120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Artículos comprados (${c.cantidadArticulos})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Tasa BCV: ${CurrencyFormat.formatRate(c.tasaBsUsd)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (c.itemsSnapshot.isEmpty)
                    const Text(
                      'Sin detalle de artículos disponible.',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textDisabled),
                    )
                  else
                    ...c.itemsSnapshot.map((snap) {
                      final n = snap['nombre'] ?? '';
                      final cant = snap['cantidad'] ?? 1;
                      final p = (snap['precioUsd'] as num?)?.toDouble() ?? 0.0;
                      final sub = p * cant;
                      final cat = Categories.fromString(snap['categoria'] ?? 'otros');
                      final meta = Categories.metaOf(cat);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(meta.emoji, style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$n (x$cant)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormat.formatUsd(sub),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          widget.onDelete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Registro eliminado del historial'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16, color: AppColors.danger),
                        label: const Text(
                          'Eliminar del historial',
                          style: TextStyle(
                              color: AppColors.danger, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

