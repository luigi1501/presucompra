import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../providers/budget_provider.dart';
import '../currency_toggle_bar.dart';

/// Modal para cálculo de pago mixto y vuelto en caja.
///
/// Diseñado para la realidad comercial venezolana:
/// Permite ingresar el monto de la cuenta (o tomarlo de la lista activa),
/// y combinar pago en efectivo USD ($) con Pago Móvil en Bolívares (Bs.),
/// calculando el restante exacto o el vuelto correspondiente.
class PaymentCalculatorModal extends StatefulWidget {
  const PaymentCalculatorModal({super.key});

  @override
  State<PaymentCalculatorModal> createState() => _PaymentCalculatorModalState();
}

class _PaymentCalculatorModalState extends State<PaymentCalculatorModal> {
  final _totalController = TextEditingController();
  final _cashController = TextEditingController();
  final _pmBsController = TextEditingController();

  MonedaPresupuesto _monedaTotal = MonedaPresupuesto.usd;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BudgetProvider>();
    if (provider.totalUsd > 0) {
      _totalController.text = provider.totalUsd.toStringAsFixed(2);
    }
    _totalController.addListener(() => setState(() {}));
    _cashController.addListener(() => setState(() {}));
    _pmBsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _totalController.dispose();
    _cashController.dispose();
    _pmBsController.dispose();
    super.dispose();
  }

  void _onMonedaTotalChanged(MonedaPresupuesto nueva) {
    if (_monedaTotal == nueva) return;
    final tasa = context.read<BudgetProvider>().tasaBsUsd;
    final clean = _totalController.text.trim().replaceAll(',', '.');
    final val = double.tryParse(clean);

    setState(() {
      _monedaTotal = nueva;
      if (val != null && val > 0 && tasa > 0) {
        if (nueva == MonedaPresupuesto.bs) {
          _totalController.text = (val * tasa).toStringAsFixed(2);
        } else {
          _totalController.text = (val / tasa).toStringAsFixed(2);
        }
      }
    });
  }

  void _setCash(double amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _cashController.text = amount.toStringAsFixed(2);
    });
  }

  void _llenarRestanteEnPagoMovil(double restanteBs) {
    HapticFeedback.selectionClick();
    setState(() {
      _pmBsController.text =
          restanteBs > 0 ? restanteBs.toStringAsFixed(2) : '0.00';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final tasaBsUsd = provider.tasaBsUsd;

    // Total a pagar de la cuenta ingresado por el usuario o de la lista
    final cleanTotal = _totalController.text.trim().replaceAll(',', '.');
    final totalInput = double.tryParse(cleanTotal) ?? 0.0;

    final double totalCuentaUsd;
    if (_monedaTotal == MonedaPresupuesto.bs) {
      totalCuentaUsd = tasaBsUsd > 0 ? (totalInput / tasaBsUsd) : 0.0;
    } else {
      totalCuentaUsd = totalInput;
    }
    final totalCuentaBs = totalCuentaUsd * tasaBsUsd;

    // Efectivo en USD entregado
    final cleanCash = _cashController.text.trim().replaceAll(',', '.');
    final cashUsd = double.tryParse(cleanCash) ?? 0.0;

    // Pago móvil en Bs entregado
    final cleanPm = _pmBsController.text.trim().replaceAll(',', '.');
    final pmBs = double.tryParse(cleanPm) ?? 0.0;
    final pmUsd = tasaBsUsd > 0 ? (pmBs / tasaBsUsd) : 0.0;

    // Total abonado combinado
    final totalAbonadoUsd = cashUsd + pmUsd;
    final diferenciaUsd = totalAbonadoUsd - totalCuentaUsd;
    final diferenciaBs = diferenciaUsd.abs() * tasaBsUsd;

    // Restante solo considerando efectivo
    final restanteSoloConEfectivoUsd = totalCuentaUsd - cashUsd;
    final restanteSoloConEfectivoBs = restanteSoloConEfectivoUsd > 0
        ? (restanteSoloConEfectivoUsd * tasaBsUsd)
        : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
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

              // ── Título ──────────────────────────────────────────────────────────
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
                      child: const Icon(Icons.point_of_sale_rounded,
                          color: AppColors.brand, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Calculadora de Caja',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Pago Mixto (Efectivo \$ + Pago Móvil Bs.) y Vuelto',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 18),

              // ── TOTAL A PAGAR (Editable) ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL DE LA CUENTA A PAGAR',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (provider.totalUsd > 0)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _monedaTotal = MonedaPresupuesto.usd;
                          _totalController.text =
                              provider.totalUsd.toStringAsFixed(2);
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.brand.withAlpha(80)),
                        ),
                        child: Text(
                          'Usar mi lista (${CurrencyFormat.formatUsd(provider.totalUsd)})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Selector de moneda para el total a pagar
              CurrencyToggleBar(
                selected: _monedaTotal,
                onChanged: _onMonedaTotalChanged,
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _totalController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+[\.,]?\d{0,2}')),
                ],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
                decoration: InputDecoration(
                  prefixText:
                      _monedaTotal == MonedaPresupuesto.usd ? '\$ ' : 'Bs. ',
                  prefixStyle: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  hintText: '0.00',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'Tasa: ${CurrencyFormat.formatRate(tasaBsUsd)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textDisabled,
                          ),
                        ),
                      ),
                      if (_totalController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _totalController.clear();
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ),

              if (totalCuentaUsd > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    _monedaTotal == MonedaPresupuesto.usd
                        ? '≈ ${CurrencyFormat.formatBs(totalCuentaBs)} Bs.'
                        : '≈ ${CurrencyFormat.formatUsd(totalCuentaUsd)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              // ── Entrada 1: Efectivo USD ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '1. Efectivo en Divisas (\$ USD)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (cashUsd > 0)
                    Text(
                      '≈ ${CurrencyFormat.formatBs(cashUsd * tasaBsUsd)} Bs.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cashController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+[\.,]?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  hintText: '0.00',
                  suffixIcon: _cashController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _cashController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),

              // Billetes rápidos USD
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [5.0, 10.0, 20.0, 50.0, 100.0].map((bill) {
                  final isSelected = cashUsd == bill;
                  return ActionChip(
                    label: Text('\$${bill.toInt()}'),
                    backgroundColor: isSelected
                        ? AppColors.brand.withAlpha(30)
                        : AppColors.backgroundBase,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.brand
                          : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.brand : AppColors.cardBorder,
                    ),
                    onPressed: () => _setCash(bill),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── Entrada 2: Pago Móvil / Punto Bs. ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '2. Pago Móvil / Punto (Bs.)',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (totalCuentaUsd > 0 && restanteSoloConEfectivoBs > 0)
                    InkWell(
                      onTap: () =>
                          _llenarRestanteEnPagoMovil(restanteSoloConEfectivoBs),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: AppColors.accent.withAlpha(90)),
                        ),
                        child: const Text(
                          'Pagar restante exacto',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pmBsController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+[\.,]?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: 'Bs. ',
                  prefixStyle: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  hintText: '0.00',
                  suffixIcon: _pmBsController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _pmBsController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              // ── Tarjeta de Resultado Dinámico ────────────────────────────────────
              if (totalCuentaUsd <= 0)
                // Si aún no se ingresa el total de la cuenta
                const _InfoCard(
                  icon: Icons.edit_note_rounded,
                  color: AppColors.warning,
                  title: 'Falta el Total de la Cuenta',
                  amountPrimary: 'Ingresa el monto a pagar arriba',
                  amountSecondary:
                      'Escribe cuánto cobra la caja para poder calcular el vuelto o el pago mixto.',
                )
              else if (totalAbonadoUsd <= 0)
                // Cuenta definida pero sin abonos aún
                _InfoCard(
                  icon: Icons.info_outline_rounded,
                  color: AppColors.accent,
                  title: 'Total a pagar en Bolívares (Pago Móvil / Punto)',
                  amountPrimary: '${CurrencyFormat.formatBs(totalCuentaBs)} Bs.',
                  amountSecondary:
                      'Equivale a ${CurrencyFormat.formatUsd(totalCuentaUsd)}',
                  onCopy: () => _copyToClipboard(
                      context, CurrencyFormat.formatBs(totalCuentaBs)),
                )
              else if (diferenciaUsd < -0.009)
                // Falta por pagar
                _InfoCard(
                  icon: Icons.phonelink_ring_rounded,
                  color: AppColors.warning,
                  title: 'Resta por pagar',
                  amountPrimary: '${CurrencyFormat.formatBs(diferenciaBs)} Bs.',
                  amountSecondary:
                      'Equivale a ${CurrencyFormat.formatUsd(diferenciaUsd.abs())}',
                  onCopy: () => _copyToClipboard(
                      context, CurrencyFormat.formatBs(diferenciaBs)),
                )
              else if (diferenciaUsd > 0.009)
                // Vuelto a favor del cliente
                _InfoCard(
                  icon: Icons.savings_rounded,
                  color: AppColors.brand,
                  title: 'Vuelto para ti (Cambio)',
                  amountPrimary: CurrencyFormat.formatUsd(diferenciaUsd),
                  amountSecondary:
                      'O en Bs.: ${CurrencyFormat.formatBs(diferenciaBs)} Bs.',
                  onCopy: () => _copyToClipboard(
                      context, CurrencyFormat.formatBs(diferenciaBs)),
                )
              else
                // Pago exacto
                _InfoCard(
                  icon: Icons.check_circle_rounded,
                  color: AppColors.brand,
                  title: '¡Pago Exacto!',
                  amountPrimary: 'Cuenta saldada',
                  amountSecondary:
                      'Efectivo (\$${cashUsd.toStringAsFixed(2)}) + Pago Móvil (${CurrencyFormat.formatBs(pmBs)} Bs.) cubren la totalidad.',
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Monto copiado: $text! Ya puedes pegarlo en el banco.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String amountPrimary;
  final String amountSecondary;
  final VoidCallback? onCopy;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.amountPrimary,
    required this.amountSecondary,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (onCopy != null)
                InkWell(
                  onTap: onCopy,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text(
                          'Copiar Bs.',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amountPrimary,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            amountSecondary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
