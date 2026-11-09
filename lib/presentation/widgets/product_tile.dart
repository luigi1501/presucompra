import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/currency_format.dart';
import '../../data/models/item_model.dart';
import '../../providers/budget_provider.dart';
import 'add_product_modal.dart';

/// Tarjeta estilizada para un artículo de la lista de compras.
///
/// Presenta:
/// - Checkbox neón (toggle comprado)
/// - Nombre y badge de categoría
/// - Controles [-] cantidad [+]
/// - Precio unitario y subtotal en USD
/// - Swipe-to-delete y tap para editar
class ProductTile extends StatelessWidget {
  final ItemModel item;

  const ProductTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final meta = Categories.metaOf(item.categoria);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: _SwipeDeleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context.read<BudgetProvider>().eliminarItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.nombre}" fue eliminado de la lista'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: item.comprado
              ? AppColors.cardSurface.withAlpha(150)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.comprado
                ? AppColors.cardBorder.withAlpha(80)
                : AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _openEditModal(context),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withAlpha(20),
          highlightColor: AppColors.primary.withAlpha(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // ── Checkbox ──────────────────────────────────────────────
                _NeonCheckbox(item: item),
                const SizedBox(width: 10),

                // ── Info principal ────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.nombre,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    decoration: item.comprado
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: item.comprado
                                        ? AppColors.textDisabled
                                        : AppColors.textPrimary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CategoryBadge(meta: meta),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${CurrencyFormat.formatUsd(item.precioUsd)} c/u',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            CurrencyFormat.formatUsd(item.subtotalUsd),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: item.comprado
                                      ? AppColors.textDisabled
                                      : AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Control de cantidad ───────────────────────────────────
                _QuantityControl(item: item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BudgetProvider>(),
        child: AddProductModal(itemToEdit: item),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Eliminar producto?',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Estás seguro de que deseas quitar "${item.nombre}" de tu lista de compras?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _NeonCheckbox extends StatelessWidget {
  final ItemModel item;
  const _NeonCheckbox({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.read<BudgetProvider>().toggleComprado(item.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: item.comprado
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: item.comprado
                ? AppColors.primary
                : AppColors.primary.withAlpha(150),
            width: 2,
          ),
          boxShadow: item.comprado
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: item.comprado
            ? const Icon(Icons.check_rounded,
                size: 16, color: AppColors.backgroundBase)
            : null,
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final CategoryMeta meta;
  const _CategoryBadge({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: meta.color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: meta.color.withAlpha(80), width: 1),
      ),
      child: Text(
        '${meta.emoji} ${_shortLabel(meta.label)}',
        style: TextStyle(
          fontSize: 10,
          color: meta.color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _shortLabel(String label) {
    // Muestra solo la primera palabra para compactar
    return label.split(' ').first;
  }
}

class _QuantityControl extends StatelessWidget {
  final ItemModel item;
  const _QuantityControl({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BudgetProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundBase,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyButton(
            icon: Icons.remove_rounded,
            onPressed: item.cantidad > 1
                ? () {
                    HapticFeedback.selectionClick();
                    provider.decrementarCantidad(item.id);
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${item.cantidad}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
            ),
          ),
          _QtyButton(
            icon: Icons.add_rounded,
            onPressed: () {
              HapticFeedback.selectionClick();
              if (provider.presupuestoMaxUsd > 0) {
                final nuevoTotal = provider.totalUsd + item.precioUsd;
                if (nuevoTotal > provider.presupuestoMaxUsd) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.warning,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      content: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.black87, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¡Atención! Has superado el presupuesto de "${provider.presupuestoActivo.nombre}" (\$${provider.presupuestoMaxUsd.toStringAsFixed(2)})',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
              provider.incrementarCantidad(item.id);
            },
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _QtyButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16),
        color: onPressed != null ? AppColors.primary : AppColors.textDisabled,
        onPressed: onPressed,
      ),
    );
  }
}

class _SwipeDeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.danger.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withAlpha(80)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
          SizedBox(width: 6),
          Text(
            'Eliminar',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

