import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../data/models/budget_model.dart';
import '../../../providers/budget_provider.dart';

/// Modal con el Dashboard y Gráfico Comparativo de Presupuestos conectados al Fondo Principal.
class BudgetDistributionModal extends StatelessWidget {
  const BudgetDistributionModal({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final principalMax = provider.presupuestoPrincipalMaxUsd;
    final totalGlobalUsd = provider.totalGlobalUsd;
    final presupuestos = provider.presupuestos;
    final tasa = provider.tasaBsUsd;

    // Suma de los presupuestos individuales
    final sumaPresupuestos = presupuestos.fold<double>(
      0.0,
      (sum, b) => sum + b.montoMaxUsd,
    );

    final disponibleSinAsignarUsd =
        principalMax > sumaPresupuestos ? (principalMax - sumaPresupuestos) : 0.0;

    // Paleta de colores para cada presupuesto
    final segmentColors = [
      AppColors.brand,
      AppColors.accent,
      AppColors.warning,
      const Color(0xFFA78BFA), // Púrpura
      const Color(0xFFF472B6), // Rosa
      const Color(0xFF38BDF8), // Sky
      const Color(0xFFFB923C), // Naranja
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: SingleChildScrollView(
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
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.pie_chart_rounded,
                          color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Distribución de Fondos',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Comparativa de tus presupuestos y consumo del Fondo Global',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 18),

              // ── Resumen Global ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F2744), AppColors.backgroundBase],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'FONDO PRINCIPAL GLOBAL',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormat.formatUsd(principalMax),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brand,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'GASTADO EN TOTAL',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormat.formatUsd(totalGlobalUsd),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: totalGlobalUsd > principalMax && principalMax > 0
                                    ? AppColors.danger
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Barra apilada comparativa
                    if (principalMax > 0 && presupuestos.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 14,
                          color: AppColors.backgroundBase,
                          child: Row(
                            children: [
                              ...presupuestos.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final b = entry.value;
                                final color = segmentColors[idx % segmentColors.length];
                                final frac = principalMax > 0
                                    ? (b.montoMaxUsd / principalMax).clamp(0.0, 1.0)
                                    : 0.0;
                                if (frac <= 0) return const SizedBox.shrink();
                                return Expanded(
                                  flex: (frac * 1000).toInt().clamp(1, 1000),
                                  child: Container(color: color),
                                );
                              }),
                              if (disponibleSinAsignarUsd > 0)
                                Expanded(
                                  flex: ((disponibleSinAsignarUsd / principalMax) * 1000)
                                      .toInt()
                                      .clamp(1, 1000),
                                  child: Container(
                                    color: AppColors.cardBorder.withAlpha(120),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Asignado: ${CurrencyFormat.formatUsd(sumaPresupuestos)} (${(principalMax > 0 ? (sumaPresupuestos / principalMax * 100) : 0).toStringAsFixed(0)}%)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Libre: ${CurrencyFormat.formatUsd(disponibleSinAsignarUsd)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Desglose por Presupuesto ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TUS LISTAS CONECTADAS (${presupuestos.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Text(
                    'Toca para abrir',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (presupuestos.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No tienes presupuestos específicos creados todavía.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...presupuestos.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final budget = entry.value;
                  final color = segmentColors[idx % segmentColors.length];
                  final gastado = provider.totalPresupuestoUsd(budget.id);
                  final cantArts = provider.itemsDelPresupuesto(budget.id).length;
                  final pctConsumo = budget.montoMaxUsd > 0
                      ? (gastado / budget.montoMaxUsd)
                      : 0.0;
                  final pctDelFondo = principalMax > 0
                      ? (budget.montoMaxUsd / principalMax * 100).toStringAsFixed(1)
                      : '0';

                  final isCurrentActive = budget.id == provider.activeBudgetId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isCurrentActive
                          ? color.withAlpha(20)
                          : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCurrentActive ? color : AppColors.cardBorder,
                        width: isCurrentActive ? 1.8 : 1,
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        provider.seleccionarPresupuesto(budget.id);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    budget.tipo.emoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        budget.nombre,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isCurrentActive
                                              ? color
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '$cantArts arts. • $pctDelFondo% del fondo global',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${CurrencyFormat.formatUsd(gastado)} / ${CurrencyFormat.formatUsd(budget.montoMaxUsd)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: pctConsumo > 1.0
                                            ? AppColors.danger
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '≈ ${CurrencyFormat.formatBs(gastado * tasa)} Bs.',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pctConsumo.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.backgroundBase,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pctConsumo > 1.0
                                      ? AppColors.danger
                                      : (pctConsumo >= 0.75
                                          ? AppColors.warning
                                          : color),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

