import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/datasources/database_helper.dart';
import '../data/datasources/bcv_service.dart';
import '../data/datasources/update_service.dart';
import '../data/models/item_model.dart';
import '../data/models/rate_model.dart';
import '../data/models/budget_model.dart';
import '../data/models/purchase_history_model.dart';
import '../core/constants/categories.dart';
import '../core/utils/currency_format.dart';

/// Estado de consumo del presupuesto.
enum BudgetStatus {
  /// Sin presupuesto definido
  undefined,

  /// Consumo < 75%
  ok,

  /// Consumo entre 75% y 100%
  warning,

  /// Consumo > 100%
  exceeded,
}

/// Tipos de presupuesto predefinidos.
enum TipoPresupuesto {
  listaMercado,
  viaje,
  estudios,
  gastosPersonales,
  otros,
}

/// Extensión con etiquetas en español y emojis para [TipoPresupuesto].
extension TipoPresupuestoExt on TipoPresupuesto {
  String get emoji {
    switch (this) {
      case TipoPresupuesto.listaMercado:
        return '🛒';
      case TipoPresupuesto.viaje:
        return '✈️';
      case TipoPresupuesto.estudios:
        return '📚';
      case TipoPresupuesto.gastosPersonales:
        return '👤';
      case TipoPresupuesto.otros:
        return '📝';
    }
  }

  String get label {
    switch (this) {
      case TipoPresupuesto.listaMercado:
        return 'Lista de Mercado';
      case TipoPresupuesto.viaje:
        return 'Viaje';
      case TipoPresupuesto.estudios:
        return 'Estudios';
      case TipoPresupuesto.gastosPersonales:
        return 'Gastos Personales';
      case TipoPresupuesto.otros:
        return 'Otros';
    }
  }

  /// True si requiere que el usuario escriba una descripción personalizada.
  bool get requiereDescripcion {
    return this == TipoPresupuesto.otros ||
        this == TipoPresupuesto.estudios ||
        this == TipoPresupuesto.gastosPersonales;
  }
}

/// Provider central de PresuCompra con soporte para Múltiples Presupuestos
/// y un Presupuesto Principal / Global que los conecta a todos.
class BudgetProvider extends ChangeNotifier {
  BudgetProvider() {
    _initialize();
  }

  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  // ── Estado interno ────────────────────────────────────────────────────────

  List<ItemModel> _items = [];
  List<BudgetModel> _budgets = [];
  List<PurchaseHistoryModel> _historial = [];
  String _activeBudgetId = '';
  double _presupuestoMasterPersonalizado = 0.0;
  bool _hasSeenTour = false;

  RateModel? _activeRate = RateModel(
    tasaBsUsd: 896.12,
    fechaRegistro: DateTime.now(),
    fuente: 'BCV',
    esActiva: true,
  );
  bool _isLoading = true;
  String? _error;

  /// Información sobre una actualización del APK disponible en GitHub
  AppUpdateInfo? _availableUpdate;
  AppUpdateInfo? get availableUpdate => _availableUpdate;

  /// Notificación de actualización del dólar BCV
  String? _bcvNotification;
  String? get bcvNotification => _bcvNotification;

  void clearBcvNotification() {
    _bcvNotification = null;
    notifyListeners();
  }

  void dismissUpdate() {
    _availableUpdate = null;
    notifyListeners();
  }

  /// Query de búsqueda activo (vacío = sin filtro).
  String _searchQuery = '';

  // ── Getters de Presupuestos (Múltiples y Principal) ────────────────────────

  /// Lista de todos los presupuestos creados.
  List<BudgetModel> get presupuestos => List.unmodifiable(_budgets);

  /// ID del presupuesto seleccionado actualmente.
  String get activeBudgetId => _activeBudgetId;

  /// True si el usuario ya ha creado al menos un presupuesto específico.
  bool get tienePresupuestos => _budgets.isNotEmpty;

  /// True si el usuario ya vio o saltó el tour de bienvenida inicial.
  bool get hasSeenTour => _hasSeenTour;

  /// Marca el tour de bienvenida como visto y lo persiste.
  Future<void> marcarTourVisto() async {
    _hasSeenTour = true;
    notifyListeners();
    await _db.setConfig('onboarding_visto', 'true');
  }

  /// Permite reiniciar la visualización del tour (para demostración).
  Future<void> reiniciarTour() async {
    _hasSeenTour = false;
    notifyListeners();
    await _db.setConfig('onboarding_visto', 'false');
  }

  /// Presupuesto activo actual.
  BudgetModel get presupuestoActivo {
    final idx = _budgets.indexWhere((b) => b.id == _activeBudgetId);
    if (idx != -1) return _budgets[idx];
    if (_budgets.isNotEmpty) return _budgets.first;
    return BudgetModel(
      id: '',
      nombre: 'Sin presupuesto',
      tipo: TipoPresupuesto.otros,
      montoMaxUsd: 0.0,
      descripcion: '',
      fechaCreacion: DateTime.now(),
    );
  }

  /// Monto máximo en USD del presupuesto activo actual.
  double get presupuestoMaxUsd =>
      _budgets.isNotEmpty ? presupuestoActivo.montoMaxUsd : 0.0;

  /// Tipo del presupuesto activo actual.
  TipoPresupuesto get tipoPresupuesto =>
      _budgets.isNotEmpty ? presupuestoActivo.tipo : TipoPresupuesto.listaMercado;

  /// Descripción del presupuesto activo actual.
  String get descripcionPresupuesto =>
      _budgets.isNotEmpty ? presupuestoActivo.descripcion : '';

  /// Nombre visible del presupuesto activo actual.
  String get nombrePresupuesto {
    if (_budgets.isEmpty) return 'Sin presupuesto seleccionado';
    final b = presupuestoActivo;
    return '${b.tipo.emoji} ${b.nombre}';
  }

  /// True si el presupuesto activo actual ya tiene monto definido.
  bool get presupuestoDefinido =>
      _budgets.isNotEmpty && presupuestoActivo.montoMaxUsd > 0;

  /// True si el Presupuesto Principal Global ya tiene un límite definido (> 0).
  bool get presupuestoPrincipalDefinido => presupuestoPrincipalMaxUsd > 0;

  // ── Cálculos del Presupuesto Principal (Global) ─────────────────────────────

  /// Presupuesto Principal / Global máximo en USD.
  /// Si se fijó un límite global personalizado, lo usa;
  /// de lo contrario, es la suma de los montos de todos los presupuestos creados.
  double get presupuestoPrincipalMaxUsd {
    if (_presupuestoMasterPersonalizado > 0) {
      return _presupuestoMasterPersonalizado;
    }
    if (_budgets.isEmpty) return 0.0;
    return _budgets.fold(0.0, (sum, b) => sum + (b.montoMaxUsd.isFinite ? b.montoMaxUsd : 0.0));
  }

  /// Total acumulado en USD de TODOS los artículos de TODOS los presupuestos.
  double get totalGlobalUsd {
    if (_items.isEmpty) return 0.0;
    return _items.fold(0.0, (sum, item) => sum + (item.subtotalUsd.isFinite ? item.subtotalUsd : 0.0));
  }

  /// Total acumulado global en Bolívares.
  double get totalGlobalBs {
    final total = totalGlobalUsd * tasaBsUsd;
    return total.isFinite ? total : 0.0;
  }

  /// Monto restante del Presupuesto Principal.
  double get presupuestoPrincipalRestanteUsd =>
      presupuestoPrincipalMaxUsd > 0
          ? (presupuestoPrincipalMaxUsd - totalGlobalUsd)
          : 0.0;

  /// Porcentaje consumido del Presupuesto Principal.
  double get porcentajePrincipalConsumido {
    if (presupuestoPrincipalMaxUsd <= 0) return 0.0;
    final pct = totalGlobalUsd / presupuestoPrincipalMaxUsd;
    return pct.isFinite ? pct.clamp(0.0, double.infinity) : 0.0;
  }

  // ── Artículos del Presupuesto Activo ────────────────────────────────────────

  /// Artículos del presupuesto seleccionado actualmente (no comprados primero).
  List<ItemModel> get items {
    if (_budgets.isEmpty) return const [];
    final list = _items
        .where((i) => i.presupuestoId == _activeBudgetId)
        .toList();
    list.sort((a, b) {
      if (a.comprado == b.comprado) return 0;
      return a.comprado ? 1 : -1;
    });
    return List.unmodifiable(list);
  }

  /// Todos los artículos del sistema sin filtrar por presupuesto.
  List<ItemModel> get allItems => List.unmodifiable(_items);

  /// Artículos pendientes de comprar en el presupuesto activo.
  List<ItemModel> get itemsPendientes =>
      items.where((i) => !i.comprado).toList();

  /// Artículos ya marcados como comprados en el presupuesto activo.
  List<ItemModel> get itemsComprados =>
      items.where((i) => i.comprado).toList();

  /// Artículos del presupuesto activo agrupados por categoría.
  Map<ProductCategory, List<ItemModel>> get itemsPorCategoria {
    final map = <ProductCategory, List<ItemModel>>{};
    for (final item in items) {
      map.putIfAbsent(item.categoria, () => []).add(item);
    }
    return map;
  }

  /// Obtiene los artículos que pertenecen a un presupuesto específico.
  List<ItemModel> itemsDelPresupuesto(String budgetId) {
    return _items.where((i) => i.presupuestoId == budgetId).toList();
  }

  /// Total gastado en USD para un presupuesto específico.
  double totalPresupuestoUsd(String budgetId) {
    return itemsDelPresupuesto(budgetId)
        .fold(0.0, (sum, i) => sum + i.subtotalUsd);
  }

  /// Historial de compras finalizadas.
  List<PurchaseHistoryModel> get historial => List.unmodifiable(_historial);

  /// Sugerencias de productos históricos basados en artículos existentes o pasados.
  List<ItemModel> sugerenciasProductos(String query) {
    if (query.trim().isEmpty) return const [];
    final q = query.trim().toLowerCase();
    final seen = <String>{};
    final results = <ItemModel>[];

    // Primero revisar en items activos y pasados
    for (final item in _items.reversed) {
      final nameLower = item.nombre.toLowerCase();
      if (nameLower.contains(q) && !seen.contains(nameLower)) {
        seen.add(nameLower);
        results.add(item);
        if (results.length >= 4) break;
      }
    }

    // Si aún hay espacio, revisar en el historial de compras
    if (results.length < 4) {
      for (final h in _historial) {
        for (final snap in h.itemsSnapshot) {
          final nombre = (snap['nombre'] as String? ?? '').trim();
          final nameLower = nombre.toLowerCase();
          if (nameLower.isNotEmpty && nameLower.contains(q) && !seen.contains(nameLower)) {
            seen.add(nameLower);
            results.add(ItemModel(
              id: 'hist_${results.length}',
              nombre: nombre,
              precioUsd: (snap['precioUsd'] as num?)?.toDouble() ?? 0.0,
              cantidad: 1,
              categoria: Categories.fromString((snap['categoria'] as String?) ?? 'otros'),
            ));
            if (results.length >= 4) break;
          }
        }
        if (results.length >= 4) break;
      }
    }

    return results;
  }

  /// Último precio registrado de un producto por su nombre.
  ItemModel? ultimoItemPorNombre(String nombre) {
    if (nombre.trim().isEmpty) return null;
    final q = nombre.trim().toLowerCase();
    for (final item in _items.reversed) {
      if (item.nombre.toLowerCase() == q) {
        return item;
      }
    }
    for (final h in _historial) {
      for (final snap in h.itemsSnapshot) {
        final n = (snap['nombre'] as String? ?? '').trim().toLowerCase();
        if (n == q) {
          return ItemModel(
            id: 'hist_last',
            nombre: (snap['nombre'] as String? ?? ''),
            precioUsd: (snap['precioUsd'] as num?)?.toDouble() ?? 0.0,
            cantidad: 1,
            categoria: Categories.fromString((snap['categoria'] as String?) ?? 'otros'),
          );
        }
      }
    }
    return null;
  }

  /// Tasa de cambio activa.
  RateModel? get activeRate => _activeRate;

  /// Valor de la tasa de cambio activa (Bs. por 1 USD).
  double get tasaBsUsd => _activeRate?.tasaBsUsd ?? 1.0;

  /// True mientras se inicializa la DB.
  bool get isLoading => _isLoading;

  /// Mensaje de error si algo falló.
  String? get error => _error;

  /// Texto de búsqueda actual.
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  // ── Cálculos del Presupuesto Activo ─────────────────────────────────────────

  /// Total en USD del presupuesto activo actual.
  double get totalUsd {
    if (items.isEmpty) return 0.0;
    return items.fold(0.0, (sum, item) => sum + (item.subtotalUsd.isFinite ? item.subtotalUsd : 0.0));
  }

  /// Total en USD pendiente del presupuesto activo.
  double get totalPendienteUsd {
    if (itemsPendientes.isEmpty) return 0.0;
    return itemsPendientes.fold(0.0, (sum, item) => sum + (item.subtotalUsd.isFinite ? item.subtotalUsd : 0.0));
  }

  /// Total en USD comprado del presupuesto activo.
  double get totalCompradoUsd {
    if (itemsComprados.isEmpty) return 0.0;
    return itemsComprados.fold(0.0, (sum, item) => sum + (item.subtotalUsd.isFinite ? item.subtotalUsd : 0.0));
  }

  /// Total en Bolívares del presupuesto activo.
  double get totalBs {
    final t = totalUsd * tasaBsUsd;
    return t.isFinite ? t : 0.0;
  }

  /// Total pendiente en Bolívares del presupuesto activo.
  double get totalPendienteBs {
    final t = totalPendienteUsd * tasaBsUsd;
    return t.isFinite ? t : 0.0;
  }

  /// Monto restante dentro del presupuesto activo (puede ser negativo).
  double get presupuestoRestanteUsd =>
      presupuestoMaxUsd > 0 ? presupuestoMaxUsd - totalUsd : 0.0;

  /// Porcentaje del presupuesto activo consumido.
  double get porcentajeConsumido {
    if (presupuestoMaxUsd <= 0) return 0.0;
    final pct = totalUsd / presupuestoMaxUsd;
    return pct.isFinite ? pct.clamp(0.0, double.infinity) : 0.0;
  }

  /// Porcentaje para la barra de progreso (clampado a 1.0).
  double get porcentajeIndicador => porcentajeConsumido.clamp(0.0, 1.0);

  /// Estado del presupuesto activo basado en el % consumido.
  BudgetStatus get budgetStatus {
    if (presupuestoMaxUsd <= 0) return BudgetStatus.undefined;
    final pct = porcentajeConsumido;
    if (pct >= 1.0) return BudgetStatus.exceeded;
    if (pct >= 0.75) return BudgetStatus.warning;
    return BudgetStatus.ok;
  }

  bool get presupuestoExcedido => budgetStatus == BudgetStatus.exceeded;

  int get totalArticulos => items.length;
  int get articulosComprados => itemsComprados.length;

  // ── Gestión de Múltiples Presupuestos ───────────────────────────────────────

  /// Cambia el presupuesto seleccionado.
  void seleccionarPresupuesto(String budgetId) {
    if (_activeBudgetId != budgetId) {
      _activeBudgetId = budgetId;
      _autoCorregirCategoriasPresupuestoActivo();
      notifyListeners();
    }
  }

  void _autoCorregirCategoriasPresupuestoActivo() {
    final budget = presupuestoActivo;
    if (budget.tipo != TipoPresupuesto.listaMercado) {
      for (int i = 0; i < _items.length; i++) {
        if (_items[i].presupuestoId == budget.id &&
            _items[i].categoria == ProductCategory.alimentos) {
          final detectada = Categories.detect(
            productName: _items[i].nombre,
            tipoPresupuesto: budget.tipo,
          );
          if (detectada != ProductCategory.alimentos) {
            _items[i] = _items[i].copyWith(categoria: detectada);
            _db.updateItem(_items[i]);
          }
        }
      }
    }
  }

  /// Crea un nuevo presupuesto y lo selecciona de inmediato.
  Future<void> crearPresupuesto({
    required String nombre,
    required TipoPresupuesto tipo,
    required double montoMaxUsd,
    String descripcion = '',
  }) async {
    final newBudget = BudgetModel(
      id: _uuid.v4(),
      nombre: nombre.trim(),
      tipo: tipo,
      montoMaxUsd: montoMaxUsd < 0 ? 0.0 : montoMaxUsd,
      descripcion: descripcion.trim(),
      fechaCreacion: DateTime.now(),
    );

    _budgets.add(newBudget);
    _activeBudgetId = newBudget.id;
    notifyListeners();

    try {
      await _db.insertBudget(newBudget);
    } catch (e) {
      debugPrint('[BudgetProvider] Error al persistir presupuesto: $e');
    }
  }

  /// Actualiza los datos de un presupuesto existente.
  Future<void> actualizarPresupuesto(BudgetModel updated) async {
    final idx = _budgets.indexWhere((b) => b.id == updated.id);
    if (idx != -1) {
      _budgets[idx] = updated;
      notifyListeners();
    }

    try {
      await _db.updateBudget(updated);
    } catch (e) {
      debugPrint('[BudgetProvider] Error al actualizar presupuesto: $e');
    }
  }

  /// Elimina un presupuesto y todos sus artículos asociados.
  Future<void> eliminarPresupuesto(String budgetId) async {
    _budgets.removeWhere((b) => b.id == budgetId);
    _items.removeWhere((i) => i.presupuestoId == budgetId);

    // Si ya no quedan presupuestos, dejar en blanco
    if (_budgets.isNotEmpty) {
      _activeBudgetId = _budgets.first.id;
    } else {
      _activeBudgetId = '';
    }
    notifyListeners();

    try {
      await _db.deleteBudget(budgetId);
    } catch (e) {
      debugPrint('[BudgetProvider] Error al eliminar presupuesto: $e');
    }
  }

  /// Define el límite máximo del Presupuesto Principal / Global.
  Future<void> setPresupuestoPrincipalMaximo(double valorUsd) async {
    _presupuestoMasterPersonalizado = valorUsd < 0 ? 0.0 : valorUsd;

    // Si solo hay un presupuesto (ej: la lista inicial) y aún no tiene monto asignado,
    // sincronizarlo con el monto principal para que el usuario pueda empezar de una vez.
    if (_budgets.length == 1 &&
        _budgets.first.montoMaxUsd == 0.0 &&
        _presupuestoMasterPersonalizado > 0) {
      _budgets[0] =
          _budgets[0].copyWith(montoMaxUsd: _presupuestoMasterPersonalizado);
      _db.updateBudget(_budgets[0]);
    }

    notifyListeners();

    try {
      await _db.insertBudget(BudgetModel(
        id: '__master__',
        nombre: 'Presupuesto Principal',
        tipo: TipoPresupuesto.otros,
        montoMaxUsd: _presupuestoMasterPersonalizado,
        fechaCreacion: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('[BudgetProvider] Error al persistir presupuesto principal: $e');
    }
  }

  /// Define o actualiza el presupuesto activo actual.
  void setPresupuestoMaximo(
    double valorUsd, {
    TipoPresupuesto tipo = TipoPresupuesto.listaMercado,
    String descripcion = '',
  }) {
    final active = presupuestoActivo;
    final updated = active.copyWith(
      montoMaxUsd: valorUsd < 0 ? 0.0 : valorUsd,
      tipo: tipo,
      descripcion: descripcion.trim(),
    );
    actualizarPresupuesto(updated);
  }

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    _isLoading = true;
    try {
      final dbFuture = Future.wait([
        _db.getAllItems(),
        _db.getActiveRate(),
        _db.getAllBudgets(),
        _db.getAllPurchases(),
      ]).timeout(const Duration(seconds: 2));

      // Pausa estética mínima (1.6s) para que la animación del carrito y el dólar se aprecie al iniciar
      final splashFuture = Future.delayed(const Duration(milliseconds: 1600));

      final results = await dbFuture;
      await splashFuture;

      _items = results[0] as List<ItemModel>;
      final rate = results[1] as RateModel?;
      if (rate != null) _activeRate = rate;
      _historial = results[3] as List<PurchaseHistoryModel>;

      final savedBudgets = results[2] as List<BudgetModel>;
      final masterIdx = savedBudgets.indexWhere((b) => b.id == '__master__');
      if (masterIdx != -1) {
        _presupuestoMasterPersonalizado = savedBudgets[masterIdx].montoMaxUsd;
        savedBudgets.removeAt(masterIdx);
      }

      // Eliminar el presupuesto predeterminado 'default' (Lista de Compras) si no tiene artículos
      // o si el usuario ya tiene otros presupuestos creados para dejar en blanco lo que no haya creado
      final defaultIdx = savedBudgets.indexWhere(
          (b) => b.id == 'default' || b.nombre == 'Lista de Compras');
      if (defaultIdx != -1) {
        final defBudget = savedBudgets[defaultIdx];
        final tieneItems = _items.any((i) => i.presupuestoId == defBudget.id);
        if (!tieneItems || savedBudgets.length > 1) {
          savedBudgets.removeAt(defaultIdx);
          _db.deleteBudget(defBudget.id);
        }
      }

      _budgets = savedBudgets;
      if (_budgets.isNotEmpty) {
        if (!_budgets.any((b) => b.id == _activeBudgetId)) {
          _activeBudgetId = _budgets.first.id;
        }
      } else {
        _activeBudgetId = '';
      }

      // Asegurar que items existentes tengan un presupuesto asociado y
      // corregir automáticamente categorías desfasadas por la versión previa
      for (int i = 0; i < _items.length; i++) {
        var item = _items[i];
        if (item.presupuestoId.isEmpty && _activeBudgetId.isNotEmpty) {
          item = item.copyWith(presupuestoId: _activeBudgetId);
        }

        // Si el artículo pertenece a un presupuesto específico (ej: Estudios)
        // pero quedó guardado como 'Alimentos' por defecto del modal anterior,
        // re-detectar automáticamente según el nombre del producto o el tipo de presupuesto
        final budgetIdx = _budgets.indexWhere((b) => b.id == item.presupuestoId);
        final budget = budgetIdx != -1 ? _budgets[budgetIdx] : null;
        if (budget != null &&
            budget.tipo != TipoPresupuesto.listaMercado &&
            item.categoria == ProductCategory.alimentos) {
          final detectada = Categories.detect(
            productName: item.nombre,
            tipoPresupuesto: budget.tipo,
          );
          if (detectada != ProductCategory.alimentos) {
            item = item.copyWith(categoria: detectada);
            _db.updateItem(item);
          }
        }
        _items[i] = item;
      }
      // Cargar estado de tour/onboarding
      final tourVisto = await _db.getConfig('onboarding_visto');
      _hasSeenTour = tourVisto == 'true';
    } catch (e) {
      debugPrint('[BudgetProvider] Inicialización rápida: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    _fetchLiveBcvRate();
  }

  Future<void> _fetchLiveBcvRate() async {
    try {
      final prevRate = _activeRate?.tasaBsUsd ?? 0.0;
      final result = await BcvService.fetchBcvRate();
      if (result.isSuccess && result.rate > 0) {
        final fueCambio = (result.rate - prevRate).abs() > 0.01;
        await actualizarTasa(
          tasaBsUsd: result.rate,
          fuente: 'BCV',
        );
        _bcvNotification = fueCambio
            ? '🟢 Tasa BCV actualizada: Bs. ${CurrencyFormat.formatBs(result.rate)}'
            : '⚡ Tasa BCV al día: Bs. ${CurrencyFormat.formatBs(result.rate)}';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[BudgetProvider] Error consultando BCV en startup: $e');
    }

    // Comprobar actualización de app en segundo plano
    try {
      final updateInfo = await UpdateService.checkUpdate();
      if (updateInfo != null && updateInfo.hasUpdate) {
        _availableUpdate = updateInfo;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[BudgetProvider] Error comprobando app update: $e');
    }
  }

  Future<LiveRateResult> consultarTasaBcv() async {
    final result = await BcvService.fetchBcvRate();
    if (result.isSuccess && result.rate > 0) {
      await actualizarTasa(
        tasaBsUsd: result.rate,
        fuente: 'BCV',
      );
    }
    return result;
  }

  Future<LiveRateResult> consultarTasaParalelo() async {
    final result = await BcvService.fetchParaleloRate();
    if (result.isSuccess && result.rate > 0) {
      await actualizarTasa(
        tasaBsUsd: result.rate,
        fuente: 'Paralelo',
      );
    }
    return result;
  }

  Future<void> reload() async {
    await _initialize();
  }

  // ── CRUD: Artículos ───────────────────────────────────────────────────────

  /// Agrega un nuevo artículo al presupuesto activo (o al especificado).
  Future<void> agregarItem({
    required String nombre,
    required double precioUsd,
    required int cantidad,
    required ProductCategory categoria,
    String? presupuestoId,
  }) async {
    final targetBudgetId = presupuestoId ?? _activeBudgetId;
    final item = ItemModel(
      id: _uuid.v4(),
      presupuestoId: targetBudgetId,
      nombre: nombre.trim(),
      precioUsd: precioUsd,
      cantidad: cantidad,
      categoria: categoria,
    );

    _items.add(item);
    notifyListeners();

    try {
      await _db.insertItem(item);
    } catch (e) {
      debugPrint('[BudgetProvider] Error al persistir en SQLite: $e');
    }
  }

  /// Actualiza un artículo existente.
  Future<void> actualizarItem(ItemModel updatedItem) async {
    final idx = _items.indexWhere((i) => i.id == updatedItem.id);
    if (idx != -1) {
      _items[idx] = updatedItem;
      notifyListeners();
    }

    try {
      await _db.updateItem(updatedItem);
    } catch (e) {
      debugPrint('[BudgetProvider] Error al actualizar en SQLite: $e');
    }
  }

  /// Elimina un artículo por su ID.
  Future<void> eliminarItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();

    try {
      await _db.deleteItem(id);
    } catch (e) {
      debugPrint('[BudgetProvider] Error al eliminar en SQLite: $e');
    }
  }

  /// Incrementa la cantidad de un artículo en 1.
  Future<void> incrementarCantidad(String id) async {
    final item = _items.firstWhere((i) => i.id == id);
    await actualizarItem(item.copyWith(cantidad: item.cantidad + 1));
  }

  /// Decrementa la cantidad de un artículo en 1 (mínimo 1).
  Future<void> decrementarCantidad(String id) async {
    final item = _items.firstWhere((i) => i.id == id);
    if (item.cantidad <= 1) return;
    await actualizarItem(item.copyWith(cantidad: item.cantidad - 1));
  }

  /// Alterna el estado de comprado de un artículo.
  Future<void> toggleComprado(String id) async {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx == -1) return;

    final nuevoEstado = !_items[idx].comprado;
    _items[idx] = _items[idx].copyWith(comprado: nuevoEstado);
    notifyListeners();

    try {
      await _db.toggleItemComprado(id, nuevoEstado);
    } catch (e) {
      debugPrint('[BudgetProvider] Error al actualizar estado en SQLite: $e');
    }
  }

  /// Elimina los artículos del presupuesto activo actual.
  Future<void> limpiarLista() async {
    try {
      final itemsAEliminar = items;
      for (final i in itemsAEliminar) {
        await _db.deleteItem(i.id);
      }
      _items.removeWhere((i) => i.presupuestoId == _activeBudgetId);
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo limpiar la lista: $e';
      notifyListeners();
      rethrow;
    }
  }

  // ── Tasa de Cambio ────────────────────────────────────────────────────────

  /// Actualiza la tasa de cambio activa.
  Future<void> actualizarTasa({
    required double tasaBsUsd,
    String fuente = 'Manual',
  }) async {
    if (tasaBsUsd <= 0) {
      _error = 'La tasa de cambio debe ser mayor a 0.';
      notifyListeners();
      return;
    }

    try {
      final nuevaTasa = await _db.insertAndActivateRate(
        tasaBsUsd: tasaBsUsd,
        fuente: fuente,
      );
      _activeRate = nuevaTasa;
      notifyListeners();
    } catch (e) {
      _error = 'No se pudo actualizar la tasa: $e';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Historial de Compras ──────────────────────────────────────────────────

  /// Finaliza la compra del presupuesto activo:
  /// 1. Crea y guarda el registro en el historial con fecha, totales y desglose.
  /// 2. Remueve los artículos de la lista activa para dejarla limpia.
  /// 3. Retorna el modelo de compra generado.
  Future<PurchaseHistoryModel?> finalizarCompra({bool soloComprados = false}) async {
    final targetItems = soloComprados
        ? itemsComprados
        : (itemsComprados.isNotEmpty ? itemsComprados : items);

    if (targetItems.isEmpty) return null;

    final totalUsdCompra = targetItems.fold<double>(
      0.0,
      (sum, item) => sum + item.subtotalUsd,
    );
    final tasa = tasaBsUsd;
    final totalBsCompra = totalUsdCompra * tasa;

    final resumen = targetItems
        .take(3)
        .map((i) => '${i.nombre} x${i.cantidad}')
        .join(', ') +
        (targetItems.length > 3 ? ' y ${targetItems.length - 3} más...' : '');

    final snapshot = targetItems.map((i) => i.toMap()).toList();

    final compra = PurchaseHistoryModel(
      id: _uuid.v4(),
      presupuestoId: presupuestoActivo.id,
      nombrePresupuesto: presupuestoActivo.nombre,
      tipoPresupuesto: presupuestoActivo.tipo,
      totalUsd: totalUsdCompra,
      totalBs: totalBsCompra,
      tasaBsUsd: tasa,
      cantidadArticulos: targetItems.length,
      fecha: DateTime.now(),
      articulosResumen: resumen,
      itemsSnapshot: snapshot,
    );

    _historial.insert(0, compra);

    // Eliminar los artículos procesados de la lista activa
    for (final i in targetItems) {
      await _db.deleteItem(i.id);
    }
    _items.removeWhere((i) => targetItems.any((t) => t.id == i.id));
    notifyListeners();

    try {
      await _db.insertPurchase(compra);
    } catch (e) {
      debugPrint('[BudgetProvider] Error al guardar compra en DB: $e');
    }

    return compra;
  }

  /// Elimina un registro del historial de compras.
  Future<void> eliminarCompraHistorial(String id) async {
    _historial.removeWhere((p) => p.id == id);
    notifyListeners();
    try {
      await _db.deletePurchase(id);
    } catch (e) {
      debugPrint('[BudgetProvider] Error al eliminar compra de DB: $e');
    }
  }
}


