import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../providers/budget_provider.dart';
import '../currency_toggle_bar.dart';

/// Modal flotante para crear un nuevo presupuesto independiente
/// que se conecta al Presupuesto Principal.
/// Permite ingresar el monto tanto en Dólares ($ USD) como en Bolívares (Bs.).
class CreateBudgetModal extends StatefulWidget {
  const CreateBudgetModal({super.key});

  /// Muestra el modal para crear un presupuesto nuevo.
  static Future<void> show(BuildContext context) {
    final provider = context.read<BudgetProvider>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const CreateBudgetModal(),
      ),
    );
  }

  @override
  State<CreateBudgetModal> createState() => _CreateBudgetModalState();
}

class _CreateBudgetModalState extends State<CreateBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  TipoPresupuesto _tipoSeleccionado = TipoPresupuesto.listaMercado;
  MonedaPresupuesto _moneda = MonedaPresupuesto.usd;

  @override
  void initState() {
    super.initState();
    _nombreController.text = _tipoSeleccionado.label;
    _montoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _onMonedaChanged(MonedaPresupuesto nueva) {
    if (_moneda == nueva) return;
    final tasa = context.read<BudgetProvider>().tasaBsUsd;
    final clean = _montoController.text.trim().replaceAll(',', '.');
    final val = double.tryParse(clean);

    setState(() {
      _moneda = nueva;
      if (val != null && val > 0 && tasa > 0) {
        if (nueva == MonedaPresupuesto.bs) {
          _montoController.text = (val * tasa).toStringAsFixed(2);
        } else {
          _montoController.text = (val / tasa).toStringAsFixed(2);
        }
      }
    });
  }

  void _onTipoChanged(TipoPresupuesto tipo) {
    setState(() {
      _tipoSeleccionado = tipo;
      if (_tipoSeleccionado != TipoPresupuesto.otros) {
        _nombreController.text = tipo.label;
      } else {
        _nombreController.text = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

                Center(
                  child: Text(
                    'Crear Nuevo Presupuesto',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Se conectará a tu Presupuesto Principal Global',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Tipo de presupuesto ───────────────────────────────────
                _FieldLabel('Tipo de presupuesto'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TipoPresupuesto.values.map((tipo) {
                    final isSelected = tipo == _tipoSeleccionado;
                    return GestureDetector(
                      onTap: () => _onTipoChanged(tipo),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withAlpha(25)
                              : AppColors.backgroundBase,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.cardBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          '${tipo.emoji} ${tipo.label}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ── Nombre del Presupuesto ─────────────────────────────────
                _FieldLabel('Nombre de la lista / presupuesto'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: _tipoSeleccionado == TipoPresupuesto.otros
                        ? 'Ej: Reparación de la casa, Cumpleaños...'
                        : 'Ej: ${_tipoSeleccionado.label}',
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Por favor, escribe un nombre para este presupuesto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Selector de Moneda y Monto Límite ─────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FieldLabel(_moneda == MonedaPresupuesto.usd
                        ? 'Monto límite asignado (USD)'
                        : 'Monto límite asignado (Bs.)'),
                    Text(
                      _moneda == MonedaPresupuesto.usd ? '💵 Dólares' : '🇻🇪 Bolívares',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CurrencyToggleBar(
                  selected: _moneda,
                  onChanged: _onMonedaChanged,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _montoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+[\.,]?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText: _moneda == MonedaPresupuesto.usd ? '\$ ' : 'Bs. ',
                    prefixStyle: TextStyle(
                      color: _moneda == MonedaPresupuesto.usd
                          ? AppColors.success
                          : AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(Icons.savings_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Por favor, ingresa el monto del presupuesto';
                    }
                    final clean = v.trim().replaceAll(',', '.');
                    final val = double.tryParse(clean);
                    if (val == null || val <= 0) {
                      return 'El monto debe ser mayor a 0';
                    }
                    return null;
                  },
                ),
                // Equivalencia en tiempo real
                Builder(
                  builder: (context) {
                    final clean = _montoController.text.trim().replaceAll(',', '.');
                    final val = double.tryParse(clean);
                    if (val == null || val <= 0) return const SizedBox.shrink();
                    final tasa = context.watch<BudgetProvider>().tasaBsUsd;
                    final equiv = _moneda == MonedaPresupuesto.usd
                        ? '≈ ${CurrencyFormat.formatBs(val * tasa)} Bs.'
                        : '≈ ${CurrencyFormat.formatUsd(tasa > 0 ? val / tasa : 0)}';
                    return Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        equiv,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // ── Descripción Opcional ──────────────────────────────────
                _FieldLabel('Detalles o notas (opcional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descripcionController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Destino, lista de compras específicas, etc.',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Botón Crear ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _crearPresupuesto,
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Crear y Abrir Presupuesto'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _crearPresupuesto() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final cleanPrice = _montoController.text.trim().replaceAll(',', '.');
    final montoInput = double.tryParse(cleanPrice) ?? 0.0;
    final descripcion = _descripcionController.text.trim();

    final provider = context.read<BudgetProvider>();
    final double montoUsd;
    if (_moneda == MonedaPresupuesto.bs) {
      final tasa = provider.tasaBsUsd;
      montoUsd = tasa > 0 ? (montoInput / tasa) : 0.0;
    } else {
      montoUsd = montoInput;
    }

    await provider.crearPresupuesto(
      nombre: nombre,
      tipo: _tipoSeleccionado,
      montoMaxUsd: montoUsd,
      descripcion: descripcion,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Presupuesto "$nombre" creado y conectado!'),
          backgroundColor: AppColors.cardSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
    );
  }
}

