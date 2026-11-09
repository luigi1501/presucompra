import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../data/models/item_model.dart';
import '../../data/datasources/bcv_service.dart';
import '../../providers/budget_provider.dart';
import '../../core/utils/currency_format.dart';
import 'cyber_cart_loader.dart';
import 'currency_toggle_bar.dart';

/// Modal flotante (BottomSheet) para agregar o editar un producto.
///
/// Maneja dos modos:
/// - [itemToEdit] == null → Modo creación
/// - [itemToEdit] != null → Modo edición
class AddProductModal extends StatefulWidget {
  final ItemModel? itemToEdit;

  const AddProductModal({super.key, this.itemToEdit});

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();

  late ProductCategory _selectedCategory;
  bool _isSaving = false;
  bool _categoriaInicializada = false; // evita sobrescribir en rebuilds
  bool _categoriaModificadaManualmente = false;

  bool get _isEditing => widget.itemToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final item = widget.itemToEdit!;
      _nombreController.text = item.nombre;
      _precioController.text = item.precioUsd.toStringAsFixed(2);
      _cantidadController.text = item.cantidad.toString();
      _selectedCategory = item.categoria;
      _categoriaInicializada = true;
      _categoriaModificadaManualmente = true;
    } else {
      _cantidadController.text = '1';
      // Categoría provisional — se sobreescribe en didChangeDependencies
      _selectedCategory = ProductCategory.alimentos;
      _nombreController.addListener(_onNombreChanged);
    }
  }

  void _onNombreChanged() {
    if (_isEditing || _categoriaModificadaManualmente) return;
    try {
      final tipo = context.read<BudgetProvider>().tipoPresupuesto;
      final detected = Categories.detect(
        productName: _nombreController.text,
        tipoPresupuesto: tipo,
      );
      if (detected != _selectedCategory) {
        setState(() {
          _selectedCategory = detected;
        });
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Solo calcular la categoría inteligente en modo creación, una sola vez
    if (!_isEditing && !_categoriaInicializada) {
      try {
        final tipo = context.read<BudgetProvider>().tipoPresupuesto;
        _selectedCategory = Categories.detect(
          productName: _nombreController.text,
          tipoPresupuesto: tipo,
        );
      } catch (_) {
        _selectedCategory = ProductCategory.alimentos;
      }
      _categoriaInicializada = true;
    }
  }

  @override
  void dispose() {
    _nombreController.removeListener(_onNombreChanged);
    _nombreController.dispose();
    _precioController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Empuja el modal sobre el teclado
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Título del modal ─────────────────────────────────────────
              Center(
                child: Text(
                  _isEditing ? 'Editar Artículo' : 'Agregar Artículo',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withAlpha(70)),
                  ),
                  child: Text(
                    'Para: ${context.watch<BudgetProvider>().nombrePresupuesto}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Nombre ───────────────────────────────────────────────────
              _FieldLabel('Nombre del producto o gasto'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nombreController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ej: Harina Pan, Carne, Pasaje...',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Por favor, escribe el nombre del producto';
                  }
                  if (v.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              // ── Sugerencias inteligentes con memoria de precios ────────────
              Builder(
                builder: (context) {
                  if (_isEditing || _nombreController.text.trim().isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final sugerencias = context
                      .watch<BudgetProvider>()
                      .sugerenciasProductos(_nombreController.text);
                  if (sugerencias.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history_rounded,
                                size: 12, color: AppColors.accent),
                            SizedBox(width: 4),
                            Text(
                              'Precios anteriores en memoria (toca para autocompletar):',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: sugerencias.map((item) {
                            final meta = Categories.metaOf(item.categoria);
                            return ActionChip(
                              avatar: Text(meta.emoji,
                                  style: const TextStyle(fontSize: 11)),
                              label: Text(
                                '${item.nombre} • ${CurrencyFormat.formatUsd(item.precioUsd)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppColors.backgroundBase,
                              side: BorderSide(
                                color: meta.color.withAlpha(120),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 0),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setState(() {
                                  _nombreController.text = item.nombre;
                                  _precioController.text =
                                      item.precioUsd.toStringAsFixed(2);
                                  _selectedCategory = item.categoria;
                                  _categoriaModificadaManualmente = true;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // ── Precio y Cantidad ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Precio unitario (USD)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _precioController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+[\.,]?\d{0,2}')),
                          ],
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            prefixText: '\$ ',
                            prefixStyle: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Por favor, ingresa el precio';
                            }
                            final clean = v.trim().replaceAll(',', '.');
                            final val = double.tryParse(clean);
                            if (val == null || val <= 0) {
                              return 'El precio debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                        // Comparador visual con el precio anterior
                        Builder(
                          builder: (context) {
                            final ultimo = context
                                .watch<BudgetProvider>()
                                .ultimoItemPorNombre(_nombreController.text);
                            if (ultimo == null) return const SizedBox.shrink();

                            final clean = _precioController.text
                                .trim()
                                .replaceAll(',', '.');
                            final precioActual = double.tryParse(clean);
                            if (precioActual == null || precioActual <= 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4, left: 2),
                                child: Text(
                                  'Último precio: ${CurrencyFormat.formatUsd(ultimo.precioUsd)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textDisabled,
                                  ),
                                ),
                              );
                            }

                            final dif = precioActual - ultimo.precioUsd;
                            if (dif.abs() < 0.009) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 4, left: 2),
                                child: Text(
                                  '⚖️ Mismo precio que la última vez',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            } else if (dif > 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4, left: 2),
                                child: Text(
                                  '📈 +${CurrencyFormat.formatUsd(dif)} más caro que antes (${CurrencyFormat.formatUsd(ultimo.precioUsd)})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4, left: 2),
                                child: Text(
                                  '📉 -${CurrencyFormat.formatUsd(dif.abs())} más barato que antes (${CurrencyFormat.formatUsd(ultimo.precioUsd)})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Cantidad'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _cantidadController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: '1',
                            prefixIcon: Icon(Icons.format_list_numbered),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Requerido';
                            }
                            final val = int.tryParse(v.trim());
                            if (val == null || val < 1) {
                              return 'Mín. 1';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Categoría del producto ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FieldLabel('Categoría'),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Categories.metaOf(_selectedCategory)
                          .color
                          .withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Categories.metaOf(_selectedCategory)
                            .color
                            .withAlpha(120),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Categories.metaOf(_selectedCategory).emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Categories.metaOf(_selectedCategory).label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Categories.metaOf(_selectedCategory).color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CategorySelector(
                selected: _selectedCategory,
                onChanged: (cat) => setState(() {
                  _selectedCategory = cat;
                  _categoriaModificadaManualmente = true;
                }),
              ),
              const SizedBox(height: 12),

              // ── Preview del subtotal ──────────────────────────────────────
              _SubtotalPreview(
                precioController: _precioController,
                cantidadController: _cantidadController,
              ),
              const SizedBox(height: 20),

              // ── Botón Guardar ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const CyberCartLoader.button(size: 20)
                      : Icon(
                          _isEditing
                              ? Icons.save_rounded
                              : Icons.add_shopping_cart_rounded,
                        ),
                  label: Text(_isEditing ? 'Guardar cambios' : 'Agregar a la lista'),
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
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final cleanPrice = _precioController.text.trim().replaceAll(',', '.');
    final precio = double.tryParse(cleanPrice) ?? 0.0;
    final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 1;
    final provider = context.read<BudgetProvider>();

    // ── Validación de Presupuesto Establecido ──────────────────────────────
    if (provider.presupuestoMaxUsd > 0) {
      final subtotalAnterior =
          _isEditing ? widget.itemToEdit!.subtotalUsd : 0.0;
      final subtotalNuevo = precio * cantidad;
      final nuevoTotal =
          (provider.totalUsd - subtotalAnterior) + subtotalNuevo;
      final limite = provider.presupuestoMaxUsd;

      if (nuevoTotal > limite) {
        final exceso = nuevoTotal - limite;
        final continuar = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.warning, width: 1.5),
            ),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Supera tu Presupuesto!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Con este artículo el total acumulado de tu lista será de \$${nuevoTotal.toStringAsFixed(2)} USD.',
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Has superado el presupuesto establecido de \$${limite.toStringAsFixed(2)} USD (por \$${exceso.toStringAsFixed(2)} USD de exceso).',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '¿Deseas agregarlo a la lista de todas formas o prefieres ajustar la cantidad?',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Ajustar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.backgroundBase,
                ),
                child: const Text('Agregar de todas formas'),
              ),
            ],
          ),
        );

        if (continuar != true) return;
      }
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        final updated = widget.itemToEdit!.copyWith(
          nombre: nombre,
          precioUsd: precio,
          cantidad: cantidad,
          categoria: _selectedCategory,
        );
        await provider.actualizarItem(updated);
      } else {
        await provider.agregarItem(
          nombre: nombre,
          precioUsd: precio,
          cantidad: cantidad,
          categoria: _selectedCategory,
          presupuestoId: provider.activeBudgetId,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? '¡"$nombre" actualizado correctamente!'
                  : '¡"$nombre" agregado a tu lista!',
            ),
            backgroundColor: AppColors.cardSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se pudo guardar el producto. Por favor revisa los datos e intenta de nuevo.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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

class _CategorySelector extends StatelessWidget {
  final ProductCategory selected;
  final ValueChanged<ProductCategory> onChanged;

  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Categories.all.map((meta) {
        final isSelected = meta.category == selected;
        return GestureDetector(
          onTap: () => onChanged(meta.category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? meta.color.withAlpha(30) : AppColors.backgroundBase,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? meta.color : AppColors.cardBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '${meta.emoji} ${meta.label.split(' ').first}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? meta.color : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SubtotalPreview extends StatefulWidget {
  final TextEditingController precioController;
  final TextEditingController cantidadController;

  const _SubtotalPreview({
    required this.precioController,
    required this.cantidadController,
  });

  @override
  State<_SubtotalPreview> createState() => _SubtotalPreviewState();
}

class _SubtotalPreviewState extends State<_SubtotalPreview> {
  @override
  void initState() {
    super.initState();
    widget.precioController.addListener(_rebuild);
    widget.cantidadController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.precioController.removeListener(_rebuild);
    widget.cantidadController.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanPrice = widget.precioController.text.trim().replaceAll(',', '.');
    final precio = double.tryParse(cleanPrice) ?? 0.0;
    final cantidad = int.tryParse(widget.cantidadController.text.trim()) ?? 0;
    final subtotal = precio * cantidad;
    final tasa = context.read<BudgetProvider>().tasaBsUsd;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withAlpha(60)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subtotal estimado',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                '\$${subtotal.toStringAsFixed(2)}',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: AppColors.success),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'En Bolívares',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                '${(subtotal * tasa).toStringAsFixed(2)} Bs.',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Modal de Tasa de Cambio ───────────────────────────────────────────────────

/// Modal flotante para cambiar la tasa Bs./USD.
class ChangeRateModal extends StatefulWidget {
  const ChangeRateModal({super.key});

  @override
  State<ChangeRateModal> createState() => _ChangeRateModalState();
}

class _ChangeRateModalState extends State<ChangeRateModal> {
  final _formKey = GlobalKey<FormState>();
  final _tasaController = TextEditingController();
  String _selectedFuente = 'BCV';
  bool _isSaving = false;
  bool _isLoadingLiveRates = false;

  double? _liveBcvRate;
  double? _liveParaleloRate;
  DateTime? _lastUpdate;

  final List<String> _fuentes = ['BCV', 'Paralelo', 'Manual'];

  @override
  void initState() {
    super.initState();
    final provider = context.read<BudgetProvider>();
    _tasaController.text = provider.tasaBsUsd.toStringAsFixed(2);
    _selectedFuente = provider.activeRate?.fuente ?? 'BCV';
    _fetchLiveRates();
  }

  Future<void> _fetchLiveRates() async {
    setState(() => _isLoadingLiveRates = true);
    try {
      final list = await BcvService.fetchAllDolares();
      for (final item in list) {
        if (item.fuente == 'BCV' && item.rate > 0) {
          _liveBcvRate = item.rate;
          _lastUpdate = item.fechaActualizacion;
        } else if (item.fuente == 'Paralelo' && item.rate > 0) {
          _liveParaleloRate = item.rate;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingLiveRates = false);
    }
  }

  void _applyLiveRate(double rate, String fuente) {
    HapticFeedback.selectionClick();
    setState(() {
      _tasaController.text = rate.toStringAsFixed(2);
      _selectedFuente = fuente;
    });
  }

  @override
  void dispose() {
    _tasaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Tasa de Cambio (Bs./USD)',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Dólar BCV',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // ── Botones de Tasas Oficiales en Vivo (BCV & Paralelo) ──────
              Row(
                children: [
                  // Tarjeta BCV
                  Expanded(
                    child: _LiveRateChip(
                      title: '🏛️ BCV Oficial',
                      rate: _liveBcvRate,
                      isLoading: _isLoadingLiveRates,
                      isSelected: _selectedFuente == 'BCV',
                      color: AppColors.brand,
                      onTap: _liveBcvRate != null
                          ? () => _applyLiveRate(_liveBcvRate!, 'BCV')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Tarjeta Paralelo
                  Expanded(
                    child: _LiveRateChip(
                      title: '⚡ Paralelo',
                      rate: _liveParaleloRate,
                      isLoading: _isLoadingLiveRates,
                      isSelected: _selectedFuente == 'Paralelo',
                      color: AppColors.accent,
                      onTap: _liveParaleloRate != null
                          ? () => _applyLiveRate(_liveParaleloRate!, 'Paralelo')
                          : null,
                    ),
                  ),
                ],
              ),

              if (_lastUpdate != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Actualizado: ${_lastUpdate!.day}/${_lastUpdate!.month}/${_lastUpdate!.year}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ── Campo de Tasa Manual / Modificable ────────────────────────
              TextFormField(
                controller: _tasaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+[\.,]?\d{0,4}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Tasa activa (Bs. por 1 \$)',
                  hintText: 'Ej: 896.12',
                  suffixText: 'Bs.',
                  suffixIcon: _isLoadingLiveRates
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CyberCartLoader.button(size: 16),
                        )
                      : IconButton(
                          icon: const Icon(Icons.sync_rounded),
                          tooltip: 'Sincronizar en vivo',
                          onPressed: _fetchLiveRates,
                        ),
                  prefixIcon: const Icon(Icons.currency_exchange_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa la tasa';
                  final clean = v.trim().replaceAll(',', '.');
                  final val = double.tryParse(clean);
                  if (val == null || val <= 0) return 'Tasa inválida';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Selector de fuente ────────────────────────────────────────
              Row(
                children: _fuentes.map((fuente) {
                  final isSelected = _selectedFuente == fuente;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFuente = fuente),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brand.withAlpha(20)
                                : AppColors.backgroundBase,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brand
                                  : AppColors.cardBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              fuente,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.brand
                                    : AppColors.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Botón Guardar ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const CyberCartLoader.button(size: 20)
                      : const Icon(Icons.check_rounded),
                  label: const Text('Aplicar Tasa a la Lista'),
                  style: FilledButton.styleFrom(
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
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final clean = _tasaController.text.trim().replaceAll(',', '.');
    final tasa = double.tryParse(clean) ?? 896.12;

    try {
      await context.read<BudgetProvider>().actualizarTasa(
            tasaBsUsd: tasa,
            fuente: _selectedFuente,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '¡Tasa actualizada a ${tasa.toStringAsFixed(2)} Bs./\$ exitosamente!'),
            backgroundColor: AppColors.cardSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se pudo actualizar la tasa de cambio. Por favor intenta de nuevo.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _LiveRateChip extends StatelessWidget {
  final String title;
  final double? rate;
  final bool isLoading;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  const _LiveRateChip({
    required this.title,
    required this.rate,
    required this.isLoading,
    required this.isSelected,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(25) : AppColors.backgroundBase,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            if (isLoading && rate == null)
              const SizedBox(
                height: 16,
                width: 16,
                child: CyberCartLoader.button(size: 14),
              )
            else
              Text(
                rate != null ? '${rate!.toStringAsFixed(2)} Bs.' : 'Consultar',
                style: TextStyle(
                  color: isSelected ? color : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Modal de Presupuesto Máximo ───────────────────────────────────────────────

/// Modal flotante para definir el presupuesto máximo en USD.
/// Incluye selección de tipo de presupuesto y campo de descripción opcional.
class SetBudgetModal extends StatefulWidget {
  /// Si es true, el usuario está obligado a establecer un presupuesto
  /// antes de poder agregar artículos (no puede cerrar sin configurarlo).
  final bool required;
  const SetBudgetModal({super.key, this.required = false});

  @override
  State<SetBudgetModal> createState() => _SetBudgetModalState();
}

class _SetBudgetModalState extends State<SetBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();

  TipoPresupuesto _tipoSeleccionado = TipoPresupuesto.listaMercado;
  MonedaPresupuesto _moneda = MonedaPresupuesto.usd;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BudgetProvider>();
    final budget = provider.presupuestoMaxUsd;
    if (budget > 0) {
      _montoController.text = budget.toStringAsFixed(2);
      _tipoSeleccionado = provider.tipoPresupuesto;
      _descripcionController.text = provider.descripcionPresupuesto;
    }
    _montoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
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

  bool get _necesitaDescripcion => _tipoSeleccionado.requiereDescripcion;

  @override
  Widget build(BuildContext context) {
    final yaDefinido = context.read<BudgetProvider>().presupuestoDefinido;

    return PopScope(
      // Si es obligatorio y aún no hay presupuesto, no permitir cerrar
      canPop: !widget.required || yaDefinido,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.required && !yaDefinido) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⚠️ Debes establecer un presupuesto antes de agregar artículos.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Handle bar ──────────────────────────────────────────
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

                  // ── Título ───────────────────────────────────────────────
                  Center(
                    child: Text(
                      widget.required
                          ? '¡Primero tu Presupuesto!'
                          : 'Presupuesto Máximo',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      widget.required
                          ? 'Define cuánto quieres gastar para comenzar'
                          : 'Define cuánto puedes gastar en esta compra',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Tipo de Presupuesto ───────────────────────────────────
                  _FieldLabel('Tipo de presupuesto'),
                  const SizedBox(height: 10),
                  _TipoPresupuestoSelector(
                    selected: _tipoSeleccionado,
                    onChanged: (tipo) =>
                        setState(() => _tipoSeleccionado = tipo),
                  ),
                  const SizedBox(height: 14),

                  // ── Campo de Descripción (si aplica) ─────────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _necesitaDescripcion
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel(
                                _tipoSeleccionado == TipoPresupuesto.otros
                                    ? '¿Para qué es este presupuesto?'
                                    : 'Descripción (opcional)',
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _descripcionController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                decoration: InputDecoration(
                                  hintText: _hintDescripcion,
                                  prefixIcon: const Icon(Icons.edit_note_rounded),
                                ),
                                validator: (v) {
                                  if (_tipoSeleccionado ==
                                          TipoPresupuesto.otros &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Por favor describe para qué es este presupuesto';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // ── Selector de Moneda y Monto ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _FieldLabel(_moneda == MonedaPresupuesto.usd
                          ? 'Monto del presupuesto (USD)'
                          : 'Monto del presupuesto (Bs.)'),
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
                    autofocus: !_necesitaDescripcion,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+[\.,]?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: _moneda == MonedaPresupuesto.usd
                          ? 'Presupuesto en USD'
                          : 'Presupuesto en Bs.',
                      hintText: _moneda == MonedaPresupuesto.usd ? 'Ej: 100.00' : 'Ej: 89600.00',
                      prefixText: _moneda == MonedaPresupuesto.usd ? '\$ ' : 'Bs. ',
                      prefixStyle: TextStyle(
                        color: _moneda == MonedaPresupuesto.usd
                            ? AppColors.success
                            : AppColors.accent,
                        fontWeight: FontWeight.w700,
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
                        return 'El presupuesto debe ser mayor a 0';
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
                  const SizedBox(height: 20),

                  // ── Botón Guardar ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _apply,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Establecer presupuesto'),
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

                  // ── Quitar presupuesto ───────────────────────────────────
                  if (!widget.required &&
                      context.read<BudgetProvider>().presupuestoDefinido) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          context
                              .read<BudgetProvider>()
                              .setPresupuestoMaximo(0);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Presupuesto desactivado.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          'Quitar presupuesto',
                          style: TextStyle(color: AppColors.textDisabled),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _hintDescripcion {
    switch (_tipoSeleccionado) {
      case TipoPresupuesto.estudios:
        return 'Ej: Materiales para Matemáticas';
      case TipoPresupuesto.gastosPersonales:
        return 'Ej: Ropa, salud, ocio...';
      case TipoPresupuesto.otros:
        return 'Escribe para qué es este presupuesto...';
      default:
        return '';
    }
  }

  Future<void> _apply() async {
    if (!_formKey.currentState!.validate()) return;

    final clean = _montoController.text.trim().replaceAll(',', '.');
    final montoInput = double.tryParse(clean) ?? 0.0;
    final provider = context.read<BudgetProvider>();
    final tasa = provider.tasaBsUsd;

    final double nuevoPresupuesto;
    if (_moneda == MonedaPresupuesto.bs) {
      nuevoPresupuesto = tasa > 0 ? (montoInput / tasa) : 0.0;
    } else {
      nuevoPresupuesto = montoInput;
    }

    final totalActual = provider.totalUsd;

    // Advertencia si el presupuesto es menor al total existente
    if (nuevoPresupuesto > 0 && totalActual > nuevoPresupuesto) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.warning, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Presupuesto Menor al Total',
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
            'El monto ingresado (${CurrencyFormat.formatUsd(nuevoPresupuesto)} / ${CurrencyFormat.formatBs(nuevoPresupuesto * tasa)} Bs.) es menor a lo que ya llevas en tu lista (${CurrencyFormat.formatUsd(totalActual)}).\n\nTu lista quedará marcada como que superó el presupuesto establecido.\n\n¿Deseas fijarlo de todas formas?',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
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
              child: const Text('Establecer'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    if (!mounted) return;
    provider.setPresupuestoMaximo(
      nuevoPresupuesto,
      tipo: _tipoSeleccionado,
      descripcion: _descripcionController.text,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '¡Presupuesto de ${CurrencyFormat.formatUsd(nuevoPresupuesto)} (${CurrencyFormat.formatBs(nuevoPresupuesto * tasa)} Bs.) establecido correctamente!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Selector de Tipo de Presupuesto ──────────────────────────────────────────

class _TipoPresupuestoSelector extends StatelessWidget {
  final TipoPresupuesto selected;
  final ValueChanged<TipoPresupuesto> onChanged;

  const _TipoPresupuestoSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TipoPresupuesto.values.map((tipo) {
        final isSelected = tipo == selected;
        return GestureDetector(
          onTap: () => onChanged(tipo),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withAlpha(25)
                  : AppColors.backgroundBase,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              '${tipo.emoji} ${tipo.label}',
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

