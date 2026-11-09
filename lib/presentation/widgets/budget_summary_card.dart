import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_format.dart';
import '../../providers/budget_provider.dart';
import '../../data/models/budget_model.dart';
import 'add_product_modal.dart';
import 'modals/create_budget_modal.dart';
import 'modals/set_main_budget_modal.dart';
import 'modals/budget_distribution_modal.dart';
import 'modals/purchase_history_modal.dart';

/// Tarjeta Hero superior con el Presupuesto Principal Global
/// y el selector interactivo de Presupuestos Conectados.
class BudgetSummaryCard extends StatelessWidget {
  const BudgetSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        // Guard de carga inicial — evita renders con datos incompletos
        // que causan 'isNegative — Receiver: null' en Flutter Web
        if (provider.isLoading) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.brand,
                strokeWidth: 2,
              ),
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2744), // Azul noche profundo
                AppColors.backgroundBase,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cardBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Encabezado: Presupuesto Principal ────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _openSetMainBudgetModal(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.brand.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.brand.withAlpha(120),
                                      width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      '🏛️ PRESUPUESTO PRINCIPAL',
                                      style: TextStyle(
                                        color: AppColors.brand,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Icon(Icons.edit_rounded,
                                        size: 11, color: AppColors.brand),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => ChangeNotifierProvider.value(
                                    value: provider,
                                    child: const BudgetDistributionModal(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.accent.withAlpha(100),
                                      width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      '📊 FONDOS',
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormat.formatUsd(provider.totalGlobalUsd),
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                color: provider.porcentajePrincipalConsumido >= 1.0
                                    ? AppColors.danger
                                    : (provider.porcentajePrincipalConsumido >= 0.75
                                        ? AppColors.warning
                                        : AppColors.success),
                              ),
                        ),
                      ],
                    ),
                    _RateBadge(provider: provider),
                  ],
                ),
              ),

              // ── Conversión Bs. Global ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                child: Text(
                  '≈ ${CurrencyFormat.formatBs(provider.totalGlobalBs)} Bs. (Total de tus listas)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Barra de Progreso del Presupuesto Principal ──────────────
              if (provider.presupuestoPrincipalMaxUsd > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: () => _openSetMainBudgetModal(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Fondo Global: ${CurrencyFormat.formatUsd(provider.presupuestoPrincipalMaxUsd)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_outlined,
                                    size: 11, color: AppColors.textSecondary),
                              ],
                            ),
                            Text(
                              '${(provider.porcentajePrincipalConsumido * 100).toStringAsFixed(0)}% asignado',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: provider.porcentajePrincipalConsumido
                                .clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: AppColors.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              provider.porcentajePrincipalConsumido >= 1.0
                                  ? AppColors.danger
                                  : AppColors.brand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () => _openSetMainBudgetModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.brand.withAlpha(80)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 16, color: AppColors.brand),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Toca aquí para colocar tu Presupuesto Principal Global',
                              style: TextStyle(
                                color: AppColors.brand,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 16, color: AppColors.brand),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ── Selector de Presupuestos Conectados ───────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TUS PRESUPUESTOS (${provider.presupuestos.length})',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    InkWell(
                      onTap: () => _openCreateBudgetModal(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_circle_outline_rounded,
                                size: 14, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text(
                              '+ Nuevo',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Carrusel de tarjetas de presupuestos
              _BudgetCardsList(provider: provider),

              const SizedBox(height: 14),

              // ── Barra de progreso del presupuesto ACTIVO ─────────────────
              if (provider.presupuestoDefinido) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ActiveBudgetDetail(provider: provider),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: _NoBudgetHint(),
                ),
              ],

              // ── Estadísticas rápidas del presupuesto seleccionado ─────────
              _QuickStats(provider: provider),
            ],
          ),
        );
      },
    );
  }

  void _openCreateBudgetModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BudgetProvider>(),
        child: const CreateBudgetModal(),
      ),
    );
  }

  void _openSetMainBudgetModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BudgetProvider>(),
        child: const SetMainBudgetModal(),
      ),
    );
  }
}

// ── Carrusel de Tarjetas de Presupuestos ──────────────────────────────────────

class _BudgetCardsList extends StatelessWidget {
  final BudgetProvider provider;
  const _BudgetCardsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final budgets = provider.presupuestos;
    final activeId = provider.activeBudgetId;

    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: budgets.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          // Última tarjeta: botón rápido para agregar nuevo
          if (index == budgets.length) {
            return GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: const CreateBudgetModal(),
                  ),
                );
              },
              child: Container(
                width: 110,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundBase.withAlpha(120),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_rounded,
                        color: AppColors.primary, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Agregar\nPresupuesto',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final budget = budgets[index];
          final isSelected = budget.id == activeId;
          final totalGastado = provider.totalPresupuestoUsd(budget.id);
          final cantArticulos = provider.itemsDelPresupuesto(budget.id).length;
          final pct = budget.montoMaxUsd > 0
              ? (totalGastado / budget.montoMaxUsd).clamp(0.0, 1.0)
              : 0.0;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              provider.seleccionarPresupuesto(budget.id);
            },
            onLongPress: () {
              _confirmDeleteBudget(context, provider, budget);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 155,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(20)
                    : AppColors.backgroundBase,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(60),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(budget.tipo.emoji,
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          budget.nombre,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            CurrencyFormat.formatUsd(totalGastado),
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$cantArticulos arts.',
                            style: const TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 4,
                          backgroundColor: AppColors.cardBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct >= 1.0 ? AppColors.danger : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteBudget(
      BuildContext context, BudgetProvider provider, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('¿Eliminar presupuesto "${budget.nombre}"?'),
        content: const Text(
          'Se eliminará este presupuesto y todos los artículos que contiene.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.eliminarPresupuesto(budget.id);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Detalle del Presupuesto Activo ───────────────────────────────────────────

class _ActiveBudgetDetail extends StatelessWidget {
  final BudgetProvider provider;
  const _ActiveBudgetDetail({required this.provider});

  @override
  Widget build(BuildContext context) {
    final active = provider.presupuestoActivo;
    final progressColor = switch (provider.budgetStatus) {
      BudgetStatus.exceeded => AppColors.danger,
      BudgetStatus.warning => AppColors.warning,
      _ => AppColors.success,
    };

    final pct = (provider.porcentajeConsumido * 100).toStringAsFixed(1);
    final restante = provider.presupuestoRestanteUsd;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundBase.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${active.tipo.emoji} ${active.nombre}: ${CurrencyFormat.formatUsd(active.montoMaxUsd)}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$pct% usado',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.porcentajeIndicador,
              minHeight: 8,
              backgroundColor: AppColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                restante >= 0
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                size: 13,
                color: progressColor,
              ),
              const SizedBox(width: 5),
              Text(
                restante >= 0
                    ? 'Disponible en este presupuesto: ${CurrencyFormat.formatUsd(restante)}'
                    : 'Excedido en este presupuesto: ${CurrencyFormat.formatUsd(restante.abs())}',
                style: TextStyle(
                  color: progressColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets auxiliares ───────────────────────────────────────────────────

class _RateBadge extends StatelessWidget {
  final BudgetProvider provider;
  const _RateBadge({required this.provider});

  @override
  Widget build(BuildContext context) {
    final fuente = provider.activeRate?.fuente ?? 'BCV';
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => ChangeNotifierProvider.value(
            value: context.read<BudgetProvider>(),
            child: const ChangeRateModal(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.brand.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.brand.withAlpha(80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sync_rounded, size: 11, color: AppColors.brand),
                const SizedBox(width: 3),
                Text(
                  'TASA $fuente',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.brand,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
            Text(
              CurrencyFormat.formatRate(provider.tasaBsUsd),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBudgetHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final sinGlobal = !provider.presupuestoPrincipalDefinido;
        final sinPresupuestos = !provider.tienePresupuestos;
        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              enableDrag: false,
              builder: (_) => ChangeNotifierProvider.value(
                value: provider,
                child: sinGlobal
                    ? const SetMainBudgetModal()
                    : (sinPresupuestos
                        ? const CreateBudgetModal()
                        : const SetBudgetModal(required: true)),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warning.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(
                  sinGlobal
                      ? Icons.account_balance_wallet_outlined
                      : (sinPresupuestos
                          ? Icons.add_chart_rounded
                          : Icons.savings_outlined),
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sinGlobal
                        ? 'Toca aquí para colocar primero tu Presupuesto Principal Global'
                        : (sinPresupuestos
                            ? 'Toca aquí para crear tu primer presupuesto'
                            : 'Toca aquí para definir el monto de este presupuesto'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.warning),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickStats extends StatelessWidget {
  final BudgetProvider provider;
  const _QuickStats({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Artículos',
            value: '${provider.totalArticulos}',
            icon: Icons.shopping_cart_outlined,
            color: AppColors.primary,
          ),
          _Divider(),
          _StatItem(
            label: 'Comprados',
            value: '${provider.articulosComprados}',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
          _Divider(),
          _StatItem(
            label: 'Pendientes',
            value: '${provider.itemsPendientes.length}',
            icon: Icons.radio_button_unchecked_rounded,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 36,
      child: VerticalDivider(
        color: AppColors.cardBorder,
        width: 1,
        thickness: 1,
      ),
    );
  }
}


