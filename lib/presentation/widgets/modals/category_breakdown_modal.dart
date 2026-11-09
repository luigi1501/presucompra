import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/categories.dart';
import '../../../core/utils/currency_format.dart';
import '../../../providers/budget_provider.dart';

/// Modal que muestra el desglose de gasto por categoría.
///
/// Permite al usuario entender rápidamente en qué se está yendo
/// la mayor parte del presupuesto (monto en USD, en Bs. y %).
class CategoryBreakdownModal extends StatelessWidget {
  const CategoryBreakdownModal({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final totalUsd = provider.totalUsd;
    final tasaBsUsd = provider.tasaBsUsd;

    // Calcular montos por categoría
    final categoryTotals = <ProductCategory, double>{};
    for (final item in provider.items) {
      categoryTotals[item.categoria] =
          (categoryTotals[item.categoria] ?? 0.0) + item.subtotalUsd;
    }

    // Ordenar de mayor a menor gasto
    final sortedCategories = Categories.all
        .where((meta) => (categoryTotals[meta.category] ?? 0.0) > 0)
        .toList()
      ..sort((a, b) => (categoryTotals[b.category] ?? 0.0)
          .compareTo(categoryTotals[a.category] ?? 0.0));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Título ───────────────────────────────────────────────────────
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pie_chart_outline_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Distribución de Gastos',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Porcentaje del presupuesto por categoría',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 20),

            if (sortedCategories.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: Text(
                    'No hay productos en la lista aún',
                    style: TextStyle(color: AppColors.textDisabled),
                  ),
                ),
              )
            else
              ...sortedCategories.map((meta) {
                final amount = categoryTotals[meta.category] ?? 0.0;
                final percentage = totalUsd > 0 ? (amount / totalUsd) : 0.0;
                final amountBs = amount * tasaBsUsd;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(meta.emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                meta.label,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${CurrencyFormat.formatUsd(amount)} (${(percentage * 100).toStringAsFixed(1)}%)',
                                style: TextStyle(
                                  color: meta.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${CurrencyFormat.formatBs(amountBs)} Bs.',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 8,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(meta.color),
                        ),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total acumulado',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    CurrencyFormat.formatUsd(totalUsd),
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

