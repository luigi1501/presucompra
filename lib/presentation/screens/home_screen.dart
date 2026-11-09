import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/share_service.dart';
import '../../core/utils/currency_format.dart';
import '../../providers/budget_provider.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/product_tile.dart';
import '../widgets/add_product_modal.dart';
import '../widgets/cyber_cart_loader.dart';
import '../widgets/modals/payment_calculator_modal.dart';
import '../widgets/modals/category_breakdown_modal.dart';
import '../widgets/modals/create_budget_modal.dart';
import '../widgets/modals/set_main_budget_modal.dart';
import '../widgets/modals/purchase_history_modal.dart';
import '../widgets/modals/budget_distribution_modal.dart';
import '../widgets/modals/onboarding_tour_modal.dart';

/// Pantalla principal de PresuCompra.
///
/// Presenta:
/// - Hero Header con [BudgetSummaryCard] (total, barra de progreso)
/// - Filtro por categoría y búsqueda en tiempo real
/// - Lista interactiva de artículos con [ProductTile]
/// - FAB para agregar productos
/// - AppBar con acciones: cambiar tasa, definir presupuesto, compartir y limpiar lista
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // null = mostrar todas las categorías
  ProductCategory? _selectedFilter;

  // Búsqueda en tiempo real
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Control para abrir el tour guiado solo la primera vez que se monta
  bool _tourChecked = false;

  void _checkFirstTimeTour(BudgetProvider provider) {
    if (_tourChecked) return;
    if (!provider.isLoading) {
      _tourChecked = true;
      if (!provider.hasSeenTour) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            OnboardingTourModal.show(
              context,
              abrirCrearPresupuestoAlFinalizar: true,
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBase,
      appBar: _buildAppBar(context),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) => _buildBody(context, provider),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          cursorColor: AppColors.brand,
          decoration: InputDecoration(
            hintText: 'Buscar en tu lista...',
            hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 15),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
      );
    }

    return AppBar(
      title: Row(
        children: [
          // Logo oficial con glow circular neón verde
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.brand,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withAlpha(90),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.shopping_cart_rounded,
                  color: AppColors.brand,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Título con tipografía estilo logo
          const Text(
            'PRESUCOMPRA',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: [
        // Buscar productos
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Buscar producto',
          color: AppColors.textSecondary,
          onPressed: () => setState(() => _isSearching = true),
        ),
        // Cambiar tasa de cambio
        IconButton(
          icon: const Icon(Icons.currency_exchange_rounded),
          tooltip: 'Cambiar tasa Bs./USD',
          color: AppColors.accent,
          onPressed: () => _showChangeRateModal(context),
        ),
        // Definir presupuesto máximo
        IconButton(
          icon: const Icon(Icons.savings_outlined),
          tooltip: 'Presupuesto máximo',
          color: AppColors.success,
          onPressed: () => _showSetBudgetModal(context),
        ),
        // Compartir lista por WhatsApp
        IconButton(
          icon: const Icon(Icons.share_rounded),
          tooltip: 'Compartir por WhatsApp',
          color: AppColors.brand,
          onPressed: () => _shareList(context),
        ),
        // Menú de opciones adicionales
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded,
              color: AppColors.textSecondary),
          color: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (_) => [
            _menuItem(
              value: 'finish_purchase',
              icon: Icons.task_alt_rounded,
              label: 'Finalizar Compra',
              color: AppColors.brand,
            ),
            _menuItem(
              value: 'history',
              icon: Icons.history_rounded,
              label: 'Historial de Compras',
              color: AppColors.textPrimary,
            ),
            const PopupMenuDivider(),
            _menuItem(
              value: 'distribution',
              icon: Icons.pie_chart_rounded,
              label: 'Distribución de Fondos',
              color: AppColors.accent,
            ),
            _menuItem(
              value: 'calculator',
              icon: Icons.point_of_sale_rounded,
              label: 'Calculadora de Caja',
              color: AppColors.brand,
            ),
            _menuItem(
              value: 'breakdown',
              icon: Icons.pie_chart_outline_rounded,
              label: 'Gastos por Categoría',
              color: AppColors.accent,
            ),
            const PopupMenuDivider(),
            _menuItem(
              value: 'new_budget',
              icon: Icons.add_chart_rounded,
              label: 'Nuevo Presupuesto',
              color: AppColors.primary,
            ),
            const PopupMenuDivider(),
            _menuItem(
              value: 'tour',
              icon: Icons.explore_rounded,
              label: 'Guía y Bienvenida (Tour)',
              color: AppColors.brand,
            ),
            _menuItem(
              value: 'clear',
              icon: Icons.delete_sweep_outlined,
              label: 'Limpiar lista actual',
              color: AppColors.danger,
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, BudgetProvider provider) {
    // Pantalla de carga inicial — evita renders con datos incompletos
    // que causan 'NoSuchMethodError: isNegative — Receiver: null' en Flutter Web
    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CyberCartLoader(),
            SizedBox(height: 16),
            Text(
              'Cargando tu lista...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Verificar si es la primera vez que ingresa para mostrar el Tour Guiado
    _checkFirstTimeTour(provider);

    final allItems = provider.items;
    final query = _searchController.text.trim().toLowerCase();

    // Filtrar por categoría seleccionada y término de búsqueda
    final filteredItems = allItems.where((i) {
      final matchesCategory =
          _selectedFilter == null || i.categoria == _selectedFilter;
      final matchesSearch =
          query.isEmpty || i.nombre.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero Header ──────────────────────────────────────────────────────
        const SliverToBoxAdapter(child: BudgetSummaryCard()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Filtros de categoría ─────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _CategoryFilterBar(
            selected: _selectedFilter,
            onChanged: (cat) => setState(() => _selectedFilter = cat),
            provider: provider,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── Lista de artículos ───────────────────────────────────────────────
        if (filteredItems.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              isFiltered: _selectedFilter != null || query.isNotEmpty,
              onAdd: () => _showAddModal(context),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Separador de sección "Comprados"
                if (index > 0 &&
                    !filteredItems[index - 1].comprado &&
                    filteredItems[index].comprado) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 14,
                              color: AppColors.textDisabled,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ya en el carrito (${provider.articulosComprados})',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textDisabled,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.cardBorder,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ProductTile(item: filteredItems[index]),
                    ],
                  );
                }

                // Encabezado de sección "Pendientes"
                if (index == 0 && !filteredItems[index].comprado) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.radio_button_unchecked_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Por comprar (${provider.itemsPendientes.length})',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      ProductTile(item: filteredItems[index]),
                    ],
                  );
                }

                return ProductTile(item: filteredItems[index]);
              },
              childCount: filteredItems.length,
            ),
          ),

        // Espacio inferior para el FAB
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  // ── FAB ─────────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, provider, _) {
        final sinPrincipal = !provider.presupuestoPrincipalDefinido;
        final sinPresupuestos = !provider.tienePresupuestos;
        final sinMontoActivo = !provider.presupuestoDefinido;
        final todoListo = !sinPrincipal && !sinPresupuestos && !sinMontoActivo;

        return FloatingActionButton.extended(
          onPressed: () => _showAddModal(context),
          backgroundColor: todoListo ? null : AppColors.warning,
          foregroundColor: todoListo ? null : AppColors.backgroundBase,
          icon: Icon(todoListo
              ? Icons.add_shopping_cart_rounded
              : (sinPrincipal
                  ? Icons.account_balance_wallet_outlined
                  : (sinPresupuestos
                      ? Icons.add_chart_rounded
                      : Icons.savings_outlined))),
          label: Text(
            todoListo
                ? 'Agregar'
                : (sinPrincipal
                    ? 'Fijar Presupuesto Principal'
                    : (sinPresupuestos
                        ? 'Crear Presupuesto'
                        : 'Fijar Presupuesto')),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }

  // ── Acciones ─────────────────────────────────────────────────────────────────

  void _showAddModal(BuildContext context) {
    final provider = context.read<BudgetProvider>();

    // 1. Si no hay Presupuesto Principal Global puesto, DEBE aparecer ese primero
    if (!provider.presupuestoPrincipalDefinido) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const SetMainBudgetModal(),
        ),
      );
      return;
    }

    // 2. Si no hay presupuestos creados todavía:
    if (!provider.tienePresupuestos) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const CreateBudgetModal(),
        ),
      );
      return;
    }

    // 3. Si ya hay presupuesto creado pero aún no tiene monto asignado:
    if (!provider.presupuestoDefinido) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const SetBudgetModal(required: true),
        ),
      ).then((_) {
        if (context.mounted &&
            context.read<BudgetProvider>().presupuestoDefinido) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) _showAddModal(context);
          });
        }
      });
      return;
    }

    // 4. Ya ambos están configurados, abrir modal para agregar producto:
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const AddProductModal(),
      ),
    );
  }

  void _showChangeRateModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<BudgetProvider>(),
        child: const ChangeRateModal(),
      ),
    );
  }

  void _showSetBudgetModal(BuildContext context) {
    final provider = context.read<BudgetProvider>();

    // Si NO tiene el global puesto, abrir DIRECTAMENTE el Presupuesto Principal Global:
    if (!provider.presupuestoPrincipalDefinido) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const SetMainBudgetModal(),
        ),
      );
      return;
    }

    // Si ya tiene el global, mostrar el menú para elegir si ajustar el global o la lista activa:
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Ajustar Presupuestos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🏛️', style: TextStyle(fontSize: 20)),
                ),
                title: const Text('Presupuesto Principal Global',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    'Fondo total: ${CurrencyFormat.formatUsd(provider.presupuestoPrincipalMaxUsd)}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ChangeNotifierProvider.value(
                      value: provider,
                      child: const SetMainBudgetModal(),
                    ),
                  );
                },
              ),
              const Divider(color: AppColors.cardBorder),
              if (provider.tienePresupuestos)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      provider.presupuestoActivo.tipo.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    'Presupuesto de "${provider.presupuestoActivo.nombre}"',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    provider.presupuestoDefinido
                        ? 'Límite: ${CurrencyFormat.formatUsd(provider.presupuestoMaxUsd)}'
                        : 'Sin límite asignado',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: const SetBudgetModal(),
                      ),
                    );
                  },
                )
              else
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_circle_outline_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  title: const Text(
                    'Crear Presupuesto Específico',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Aún no tienes presupuestos creados'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: provider,
                        child: const CreateBudgetModal(),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareList(BuildContext context) async {
    final provider = context.read<BudgetProvider>();
    if (provider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu lista de compras está vacía. Agrega productos antes de compartir.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final wasCopied = await ShareService.compartirLista(
        items: provider.items,
        tasaBsUsd: provider.tasaBsUsd,
        presupuestoMaxUsd: provider.presupuestoMaxUsd,
        titulo: provider.nombrePresupuesto,
      );
      if (context.mounted && wasCopied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 ¡Lista copiada al portapapeles! Ya puedes enviarla por WhatsApp.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir la lista. Por favor intenta de nuevo.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleMenuAction(BuildContext context, String action) async {
    final provider = context.read<BudgetProvider>();

    if (action == 'finish_purchase') {
      await _finalizarCompra(context);
    } else if (action == 'history') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const PurchaseHistoryModal(),
        ),
      );
    } else if (action == 'distribution') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const BudgetDistributionModal(),
        ),
      );
    } else if (action == 'new_budget') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const CreateBudgetModal(),
        ),
      );
    } else if (action == 'calculator') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const PaymentCalculatorModal(),
        ),
      );
    } else if (action == 'breakdown') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const CategoryBreakdownModal(),
        ),
      );
    } else if (action == 'tour') {
      OnboardingTourModal.show(context);
    } else if (action == 'clear') {
      if (provider.items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu lista de compras ya está vacía.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('¿Vaciar lista de compras?',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          content: const Text(
            'Se borrarán todos los artículos de tu lista actual. Esta acción no se puede deshacer.',
            style: TextStyle(color: AppColors.textSecondary),
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
              child: const Text('Vaciar todo'),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        await provider.limpiarLista();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La lista de compras ha sido vaciada.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _finalizarCompra(BuildContext context) async {
    final provider = context.read<BudgetProvider>();
    if (provider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay artículos para finalizar en este presupuesto.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cantComprados = provider.articulosComprados;
    final totalUsd = cantComprados > 0
        ? provider.totalCompradoUsd
        : provider.totalUsd;
    final totalBs = totalUsd * provider.tasaBsUsd;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.brand, width: 1.5)),
        title: const Row(
          children: [
            Icon(Icons.task_alt_rounded, color: AppColors.brand, size: 24),
            SizedBox(width: 8),
            Text('¿Finalizar compra?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Se registrará una compra por ${CurrencyFormat.formatUsd(totalUsd)} (${CurrencyFormat.formatBs(totalBs)} Bs.) en tu Historial de Compras.',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              cantComprados > 0
                  ? 'Se archivarán los $cantComprados artículos marcados como comprados y la lista quedará lista para tu próxima compra.'
                  : 'Se archivarán todos los ${provider.totalArticulos} artículos de esta lista y quedará limpia para tu próxima compra.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirmar y Guardar'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: AppColors.backgroundBase,
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final compra = await provider.finalizarCompra(
        soloComprados: cantComprados > 0,
      );
      if (context.mounted && compra != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 ¡Compra finalizada y archivada en tu Historial! (${CurrencyFormat.formatUsd(compra.totalUsd)})',
            ),
            backgroundColor: AppColors.cardSurface,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Ver Historial',
              textColor: AppColors.brand,
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ChangeNotifierProvider.value(
                    value: provider,
                    child: const PurchaseHistoryModal(),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }
}

// ── Sub-widgets de la pantalla ────────────────────────────────────────────────

class _CategoryFilterBar extends StatelessWidget {
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onChanged;
  final BudgetProvider provider;

  const _CategoryFilterBar({
    required this.selected,
    required this.onChanged,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Chip "Todos"
          _FilterChip(
            label: '🧾 Todos',
            isSelected: selected == null,
            count: provider.totalArticulos,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          // Chips de categoría
          ...Categories.all.map((meta) {
            final count = provider.items
                .where((i) => i.categoria == meta.category)
                .length;
            if (count == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: '${meta.emoji} ${meta.label.split(' ').first}',
                isSelected: selected == meta.category,
                count: count,
                color: meta.color,
                onTap: () => onChanged(
                  selected == meta.category ? null : meta.category,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withAlpha(25)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? activeColor : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withAlpha(40)
                      : AppColors.backgroundBase,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? activeColor : AppColors.textDisabled,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback onAdd;

  const _EmptyState({required this.isFiltered, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contenedor circular con glow del logo oficial
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brand, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withAlpha(60),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: isFiltered
                    ? const Icon(
                        Icons.filter_list_off_rounded,
                        size: 40,
                        color: AppColors.brand,
                      )
                    : Image.asset(
                        'assets/images/logo.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.shopping_cart_outlined,
                          size: 40,
                          color: AppColors.brand,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered
                  ? 'Sin artículos en esta categoría'
                  : 'Tu lista está vacía',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (ctx) {
                final provider = ctx.watch<BudgetProvider>();
                final tienePresupuesto = provider.presupuestoDefinido;
                if (isFiltered) {
                  return Text(
                    'Selecciona otra categoría o agrega productos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  );
                }
                if (!provider.presupuestoPrincipalDefinido) {
                  return const Text(
                    'Primero establece tu Presupuesto Principal Global y luego podrás armar tus listas de compras.',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  );
                }
                if (!provider.tienePresupuestos) {
                  return const Text(
                    'Crea tu primer presupuesto específico con el botón "+ Nuevo" arriba para comenzar a agregar artículos.',
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  );
                }
                return Text(
                  tienePresupuesto
                      ? 'Toca el botón para agregar tu primer artículo a "${provider.presupuestoActivo.nombre}".'
                      : 'Define el monto para "${provider.presupuestoActivo.nombre}" y luego agrega artículos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                );
              },
            ),
            if (!isFiltered) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  !context.watch<BudgetProvider>().presupuestoPrincipalDefinido
                      ? 'Fijar Presupuesto Principal'
                      : (!context.watch<BudgetProvider>().tienePresupuestos
                          ? 'Crear Presupuesto'
                          : (context.watch<BudgetProvider>().presupuestoDefinido
                              ? 'Agregar a ${context.watch<BudgetProvider>().presupuestoActivo.nombre}'
                              : 'Fijar Presupuesto de Lista')),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CyberCartLoader(
        size: 64,
        message: 'Cargando tu lista...',
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Algo salió mal',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

