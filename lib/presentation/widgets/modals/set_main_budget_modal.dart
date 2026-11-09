import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../providers/budget_provider.dart';
import '../currency_toggle_bar.dart';

/// Modal flotante para definir el Presupuesto Principal (Global)
/// que respalda y conecta todas las listas y presupuestos.
/// Permite ingresar el monto tanto en Dólares ($ USD) como en Bolívares (Bs.).
class SetMainBudgetModal extends StatefulWidget {
  const SetMainBudgetModal({super.key});

  @override
  State<SetMainBudgetModal> createState() => _SetMainBudgetModalState();
}

class _SetMainBudgetModalState extends State<SetMainBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  MonedaPresupuesto _moneda = MonedaPresupuesto.usd;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BudgetProvider>();
    final principal = provider.presupuestoPrincipalMaxUsd;
    if (principal > 0) {
      _controller.text = principal.toStringAsFixed(2);
    }
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onMonedaChanged(MonedaPresupuesto nueva) {
    if (_moneda == nueva) return;
    final tasa = context.read<BudgetProvider>().tasaBsUsd;
    final clean = _controller.text.trim().replaceAll(',', '.');
    final val = double.tryParse(clean);

    setState(() {
      _moneda = nueva;
      if (val != null && val > 0 && tasa > 0) {
        if (nueva == MonedaPresupuesto.bs) {
          // De USD a Bs.
          _controller.text = (val * tasa).toStringAsFixed(2);
        } else {
          // De Bs. a USD
          _controller.text = (val / tasa).toStringAsFixed(2);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final totalGlobalUsd = provider.totalGlobalUsd;
    final totalGlobalBs = provider.totalGlobalBs;
    final sumaPresupuestos =
        provider.presupuestos.fold(0.0, (sum, b) => sum + b.montoMaxUsd);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Form(
          key: _formKey,
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
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Título ─────────────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('🏛️', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Presupuesto Principal',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Define tu fondo global en Dólares o Bolívares para distribuir entre tus listas',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),

                // ── Selector de Moneda (USD / Bs.) ─────────────────────────
                CurrencyToggleBar(
                  selected: _moneda,
                  onChanged: _onMonedaChanged,
                ),
                const SizedBox(height: 16),

                // ── Campo de Monto ─────────────────────────────────────────
                Text(
                  _moneda == MonedaPresupuesto.usd
                      ? 'Fondo o Presupuesto Total (\$ USD)'
                      : 'Fondo o Presupuesto Total (Bs. Bolívares)',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+[\.,]?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: _moneda == MonedaPresupuesto.usd
                        ? 'Ej: 500.00'
                        : 'Ej: 50000.00',
                    prefixText: _moneda == MonedaPresupuesto.usd ? '\$ ' : 'Bs. ',
                    prefixStyle: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Por favor, ingresa el monto total';
                    }
                    final clean = v.trim().replaceAll(',', '.');
                    final val = double.tryParse(clean);
                    if (val == null || val <= 0) {
                      return 'El monto debe ser mayor a 0';
                    }
                    return null;
                  },
                ),

                // ── Conversión en tiempo real ──────────────────────────────
                Builder(
                  builder: (context) {
                    final clean = _controller.text.trim().replaceAll(',', '.');
                    final val = double.tryParse(clean) ?? 0.0;
                    if (val <= 0) return const SizedBox.shrink();

                    final tasa = provider.tasaBsUsd;
                    final equivUsd = _moneda == MonedaPresupuesto.usd
                        ? val
                        : (tasa > 0 ? val / tasa : 0.0);
                    final equivBs = _moneda == MonedaPresupuesto.bs
                        ? val
                        : (val * tasa);

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: AppColors.brand.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sync_alt_rounded,
                                size: 14, color: AppColors.brand),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _moneda == MonedaPresupuesto.bs
                                    ? 'Equivale a ${CurrencyFormat.formatUsd(equivUsd)} (Tasa BCV: ${CurrencyFormat.formatRate(tasa)})'
                                    : 'Equivale a ${CurrencyFormat.formatBs(equivBs)} Bs. (Tasa BCV: ${CurrencyFormat.formatRate(tasa)})',
                                style: const TextStyle(
                                  color: AppColors.brand,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── Tarjeta Informativa de Conexión ────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundBase,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total gastado actualmente:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            CurrencyFormat.formatUsd(totalGlobalUsd),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Equivalente en Bolívares (BCV):',
                            style: TextStyle(
                              color: AppColors.textDisabled,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '${CurrencyFormat.formatBs(totalGlobalBs)} Bs.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16, color: AppColors.cardBorder),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Suma de tus ${provider.presupuestos.length} presupuestos:',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            CurrencyFormat.formatUsd(sumaPresupuestos),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Botón Guardar ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _guardar,
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Fijar Presupuesto Principal'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.backgroundBase,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Botón Suma Automática ──────────────────────────────────
                if (sumaPresupuestos > 0)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        context
                            .read<BudgetProvider>()
                            .setPresupuestoPrincipalMaximo(0);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'El Presupuesto Principal ahora se calcula automáticamente según tus listas.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: Text(
                        'Calcular automáticamente (${CurrencyFormat.formatUsd(sumaPresupuestos)})',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final clean = _controller.text.trim().replaceAll(',', '.');
    final valInput = double.tryParse(clean) ?? 0.0;
    final provider = context.read<BudgetProvider>();
    final tasa = provider.tasaBsUsd;

    final double montoUsd = _moneda == MonedaPresupuesto.usd
        ? valInput
        : (tasa > 0 ? valInput / tasa : 0.0);
    final double montoBs = _moneda == MonedaPresupuesto.bs
        ? valInput
        : (montoUsd * tasa);

    // Advertencia si es menor a lo ya gastado en total
    if (montoUsd > 0 && provider.totalGlobalUsd > montoUsd) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fondo Menor al Gasto Actual',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'El monto ingresado (${CurrencyFormat.formatUsd(montoUsd)} / ${CurrencyFormat.formatBs(montoBs)} Bs.) es menor al total que ya llevas gastado entre todas tus listas (${CurrencyFormat.formatUsd(provider.totalGlobalUsd)}).\n\nTu Presupuesto Principal quedará marcado como excedido.\n\n¿Deseas fijarlo de todas formas?',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Corregir'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: AppColors.backgroundBase,
              ),
              child: const Text('Fijar de todas formas'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    if (!mounted) return;
    await provider.setPresupuestoPrincipalMaximo(montoUsd);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '¡Presupuesto Principal fijado en ${CurrencyFormat.formatUsd(montoUsd)} (${CurrencyFormat.formatBs(montoBs)} Bs.)!'),
        backgroundColor: AppColors.cardSurface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

