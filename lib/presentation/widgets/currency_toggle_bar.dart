import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Moneda elegida para ingresar o visualizar un presupuesto.
enum MonedaPresupuesto {
  usd,
  bs;

  String get simbolo => this == MonedaPresupuesto.usd ? '\$' : 'Bs.';
  String get etiqueta => this == MonedaPresupuesto.usd ? 'USD' : 'Bs.';
}

/// Selector de moneda elegante Cyber-Clean con pestañas para $ USD y Bs.
class CurrencyToggleBar extends StatelessWidget {
  final MonedaPresupuesto selected;
  final ValueChanged<MonedaPresupuesto> onChanged;

  const CurrencyToggleBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.backgroundBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: '💵 Dólares (\$ USD)',
              isSelected: selected == MonedaPresupuesto.usd,
              onTap: () => onChanged(MonedaPresupuesto.usd),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              label: '🇻🇪 Bolívares (Bs.)',
              isSelected: selected == MonedaPresupuesto.bs,
              onTap: () => onChanged(MonedaPresupuesto.bs),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brand.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? AppColors.brand : Colors.transparent,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.brand : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

