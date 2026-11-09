import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/item_model.dart';
import '../models/rate_model.dart';
import '../models/budget_model.dart';
import '../models/purchase_history_model.dart';
import '../../providers/budget_provider.dart';

/// Helper de acceso a la base de datos SQLite local.
///
/// Implementa el patrón Singleton para garantizar una única
/// instancia de [Database] durante el ciclo de vida de la app.
/// Toda la persistencia es local y offline-first.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;
  bool _sqliteAvailable = true;

  // Fallback en memoria si SQLite no está disponible o falla
  final List<ItemModel> _memoryItems = [];
  final List<BudgetModel> _memoryBudgets = [];
  final List<PurchaseHistoryModel> _memoryPurchases = [];
  final Map<String, String> _memoryConfig = {};
  final List<RateModel> _memoryRates = [
    RateModel(
      id: 1,
      tasaBsUsd: 896.12,
      fechaRegistro: DateTime.now(),
      fuente: 'BCV',
      esActiva: true,
    ),
  ];

  // ── Configuración ─────────────────────────────────────────────────────────
  static const String _dbName = 'presucompra.db';
  static const int _dbVersion = 2;

  // Tabla items
  static const String _tableItems = 'items';
  static const String _colItemId = 'id';
  static const String _colItemPresupuestoId = 'presupuestoId';
  static const String _colItemNombre = 'nombre';
  static const String _colItemPrecioUsd = 'precioUsd';
  static const String _colItemCantidad = 'cantidad';
  static const String _colItemCategoria = 'categoria';
  static const String _colItemComprado = 'comprado';

  // Tabla presupuestos
  static const String _tableBudgets = 'presupuestos';
  static const String _colBudgetId = 'id';
  static const String _colBudgetNombre = 'nombre';
  static const String _colBudgetTipo = 'tipo';
  static const String _colBudgetMontoMax = 'montoMaxUsd';
  static const String _colBudgetDescripcion = 'descripcion';
  static const String _colBudgetFecha = 'fechaCreacion';

  // Tabla tasas
  static const String _tableRates = 'tasas';
  static const String _colRateId = 'id';
  static const String _colRateTasa = 'tasaBsUsd';
  static const String _colRateFecha = 'fechaRegistro';
  static const String _colRateFuente = 'fuente';
  static const String _colRateActiva = 'esActiva';

  // Tabla historial de compras
  static const String _tableHistory = 'compras_historial';
  static const String _colHistoryId = 'id';
  static const String _colHistoryPresupuestoId = 'presupuestoId';
  static const String _colHistoryNombre = 'nombrePresupuesto';
  static const String _colHistoryTipo = 'tipoPresupuesto';
  static const String _colHistoryTotalUsd = 'totalUsd';
  static const String _colHistoryTotalBs = 'totalBs';
  static const String _colHistoryTasa = 'tasaBsUsd';
  static const String _colHistoryCant = 'cantidadArticulos';
  static const String _colHistoryFecha = 'fecha';
  static const String _colHistoryResumen = 'articulosResumen';
  static const String _colHistoryItemsJson = 'itemsJson';

  // Tabla configuración / preferencias clave-valor
  static const String _tableConfig = 'configuracion';
  static const String _colConfigClave = 'clave';
  static const String _colConfigValor = 'valor';

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<Database?> get database async {
    if (kIsWeb) return null; // En Web usamos almacenamiento seguro en memoria
    if (!_sqliteAvailable) return null;
    if (_database != null) return _database;
    try {
      _database = await _initDatabase();
      return _database;
    } catch (e) {
      debugPrint('[DatabaseHelper] Advertencia: SQLite no disponible ($e). Usando almacenamiento en memoria.');
      _sqliteAvailable = false;
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final String path;
    if (kIsWeb) {
      path = _dbName;
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, _dbName);
    }

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de presupuestos
    await db.execute('''
      CREATE TABLE $_tableBudgets (
        $_colBudgetId          TEXT PRIMARY KEY NOT NULL,
        $_colBudgetNombre      TEXT NOT NULL,
        $_colBudgetTipo        TEXT NOT NULL,
        $_colBudgetMontoMax    REAL NOT NULL DEFAULT 0.0,
        $_colBudgetDescripcion TEXT DEFAULT '',
        $_colBudgetFecha       TEXT NOT NULL
      )
    ''');

    // Tabla de artículos/productos
    await db.execute('''
      CREATE TABLE $_tableItems (
        $_colItemId            TEXT PRIMARY KEY NOT NULL,
        $_colItemPresupuestoId TEXT NOT NULL DEFAULT 'default',
        $_colItemNombre        TEXT NOT NULL,
        $_colItemPrecioUsd     REAL NOT NULL DEFAULT 0.0,
        $_colItemCantidad      INTEGER NOT NULL DEFAULT 1,
        $_colItemCategoria     TEXT NOT NULL,
        $_colItemComprado      INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabla de tasas de cambio
    await db.execute('''
      CREATE TABLE $_tableRates (
        $_colRateId     INTEGER PRIMARY KEY AUTOINCREMENT,
        $_colRateTasa   REAL NOT NULL,
        $_colRateFecha  TEXT NOT NULL,
        $_colRateFuente TEXT DEFAULT 'BCV',
        $_colRateActiva INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insertar tasa inicial de referencia BCV
    await db.insert(_tableRates, {
      _colRateTasa: 896.12,
      _colRateFecha: DateTime.now().toIso8601String(),
      _colRateFuente: 'BCV',
      _colRateActiva: 1,
    });

    // Tabla historial de compras
    await db.execute('''
      CREATE TABLE $_tableHistory (
        $_colHistoryId            TEXT PRIMARY KEY NOT NULL,
        $_colHistoryPresupuestoId TEXT NOT NULL,
        $_colHistoryNombre        TEXT NOT NULL,
        $_colHistoryTipo          TEXT NOT NULL,
        $_colHistoryTotalUsd      REAL NOT NULL DEFAULT 0.0,
        $_colHistoryTotalBs       REAL NOT NULL DEFAULT 0.0,
        $_colHistoryTasa          REAL NOT NULL DEFAULT 1.0,
        $_colHistoryCant          INTEGER NOT NULL DEFAULT 0,
        $_colHistoryFecha         TEXT NOT NULL,
        $_colHistoryResumen       TEXT DEFAULT '',
        $_colHistoryItemsJson     TEXT DEFAULT '[]'
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableBudgets (
            $_colBudgetId          TEXT PRIMARY KEY NOT NULL,
            $_colBudgetNombre      TEXT NOT NULL,
            $_colBudgetTipo        TEXT NOT NULL,
            $_colBudgetMontoMax    REAL NOT NULL DEFAULT 0.0,
            $_colBudgetDescripcion TEXT DEFAULT '',
            $_colBudgetFecha       TEXT NOT NULL
          )
        ''');
        await db.execute('''
          ALTER TABLE $_tableItems ADD COLUMN $_colItemPresupuestoId TEXT DEFAULT 'default'
        ''');
      } catch (e) {
        debugPrint('[DatabaseHelper] Upgrade migración: $e');
      }
    }
  }

  // ── CRUD: Presupuestos ────────────────────────────────────────────────────

  Future<void> insertBudget(BudgetModel budget) async {
    final idx = _memoryBudgets.indexWhere((b) => b.id == budget.id);
    if (idx != -1) {
      _memoryBudgets[idx] = budget;
    } else {
      _memoryBudgets.add(budget);
    }

    try {
      final db = await database;
      if (db != null) {
        await db.insert(
          _tableBudgets,
          budget.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al insertar presupuesto: $e');
    }
  }

  Future<List<BudgetModel>> getAllBudgets() async {
    try {
      final db = await database;
      if (db != null) {
        final maps = await db.query(_tableBudgets, orderBy: '$_colBudgetFecha ASC');
        if (maps.isNotEmpty) {
          _memoryBudgets.clear();
          _memoryBudgets.addAll(maps.map(BudgetModel.fromMap));
          return List.from(_memoryBudgets);
        }
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al obtener presupuestos de SQLite: $e');
    }
    return List.from(_memoryBudgets);
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final idx = _memoryBudgets.indexWhere((b) => b.id == budget.id);
    if (idx != -1) {
      _memoryBudgets[idx] = budget;
    }

    try {
      final db = await database;
      if (db != null) {
        await db.update(
          _tableBudgets,
          budget.toMap(),
          where: '$_colBudgetId = ?',
          whereArgs: [budget.id],
        );
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al actualizar presupuesto: $e');
    }
  }

  Future<void> deleteBudget(String id) async {
    _memoryBudgets.removeWhere((b) => b.id == id);
    _memoryItems.removeWhere((i) => i.presupuestoId == id);

    try {
      final db = await database;
      if (db != null) {
        await db.delete(_tableBudgets, where: '$_colBudgetId = ?', whereArgs: [id]);
        await db.delete(_tableItems, where: '$_colItemPresupuestoId = ?', whereArgs: [id]);
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al eliminar presupuesto: $e');
    }
  }

  // ── CRUD: Items ───────────────────────────────────────────────────────────

  /// Inserta un nuevo artículo o reemplaza si existe.
  Future<void> insertItem(ItemModel item) async {
    // Siempre asegurar en memoria
    final idx = _memoryItems.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      _memoryItems[idx] = item;
    } else {
      _memoryItems.add(item);
    }

    // Persistir en SQLite si está disponible
    try {
      final db = await database;
      if (db != null) {
        await db.insert(
          _tableItems,
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al insertar en SQLite: $e');
    }
  }

  /// Obtiene todos los artículos de la lista actual.
  Future<List<ItemModel>> getAllItems() async {
    try {
      final db = await database;
      if (db != null) {
        final maps = await db.query(_tableItems, orderBy: '$_colItemComprado ASC');
        final items = maps.map(ItemModel.fromMap).toList();
        _memoryItems.clear();
        _memoryItems.addAll(items);
        return List.from(_memoryItems);
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al obtener items de SQLite: $e');
    }
    return List.from(_memoryItems);
  }

  /// Actualiza un artículo existente por ID.
  Future<void> updateItem(ItemModel item) async {
    final idx = _memoryItems.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      _memoryItems[idx] = item;
    }

    try {
      final db = await database;
      if (db != null) {
        await db.update(
          _tableItems,
          item.toMap(),
          where: '$_colItemId = ?',
          whereArgs: [item.id],
        );
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al actualizar item en SQLite: $e');
    }
  }

  /// Elimina un artículo por ID.
  Future<void> deleteItem(String id) async {
    _memoryItems.removeWhere((i) => i.id == id);

    try {
      final db = await database;
      if (db != null) {
        await db.delete(
          _tableItems,
          where: '$_colItemId = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al eliminar item en SQLite: $e');
    }
  }

  /// Elimina todos los artículos (resetear lista).
  Future<void> clearAllItems() async {
    _memoryItems.clear();

    try {
      final db = await database;
      if (db != null) {
        await db.delete(_tableItems);
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al vaciar items en SQLite: $e');
    }
  }

  /// Marca/desmarca un artículo como comprado.
  Future<void> toggleItemComprado(String id, bool comprado) async {
    final idx = _memoryItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _memoryItems[idx] = _memoryItems[idx].copyWith(comprado: comprado);
    }

    try {
      final db = await database;
      if (db != null) {
        await db.update(
          _tableItems,
          {_colItemComprado: comprado ? 1 : 0},
          where: '$_colItemId = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al toggle comprado en SQLite: $e');
    }
  }

  // ── CRUD: Tasas ───────────────────────────────────────────────────────────

  /// Obtiene la tasa de cambio actualmente activa.
  Future<RateModel?> getActiveRate() async {
    try {
      final db = await database;
      if (db != null) {
        final maps = await db.query(
          _tableRates,
          where: '$_colRateActiva = ?',
          whereArgs: [1],
          limit: 1,
        );
        if (maps.isNotEmpty) {
          final rate = RateModel.fromMap(maps.first);
          _memoryRates.clear();
          _memoryRates.add(rate);
          return rate;
        }
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al obtener tasa activa de SQLite: $e');
    }
    return _memoryRates.isNotEmpty ? _memoryRates.first : null;
  }

  /// Obtiene todas las tasas registradas (historial).
  Future<List<RateModel>> getAllRates() async {
    try {
      final db = await database;
      if (db != null) {
        final maps = await db.query(
          _tableRates,
          orderBy: '$_colRateFecha DESC',
        );
        return maps.map(RateModel.fromMap).toList();
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al obtener historial de tasas: $e');
    }
    return List.from(_memoryRates);
  }

  /// Inserta una nueva tasa y la marca como activa.
  Future<RateModel> insertAndActivateRate({
    required double tasaBsUsd,
    String fuente = 'BCV',
  }) async {
    final now = DateTime.now();
    final newRate = RateModel(
      id: _memoryRates.length + 1,
      tasaBsUsd: tasaBsUsd,
      fechaRegistro: now,
      fuente: fuente,
      esActiva: true,
    );

    _memoryRates.insert(0, newRate);

    try {
      final db = await database;
      if (db != null) {
        await db.transaction((txn) async {
          await txn.update(
            _tableRates,
            {_colRateActiva: 0},
            where: '$_colRateActiva = ?',
            whereArgs: [1],
          );
          final id = await txn.insert(_tableRates, {
            _colRateTasa: tasaBsUsd,
            _colRateFecha: now.toIso8601String(),
            _colRateFuente: fuente,
            _colRateActiva: 1,
          });
          return newRate.copyWith(id: id);
        });
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al insertar tasa en SQLite: $e');
    }

    return newRate;
  }

  // ── CRUD: Historial de Compras ───────────────────────────────────────────

  /// Registra una compra finalizada en el historial.
  Future<void> insertPurchase(PurchaseHistoryModel purchase) async {
    final idx = _memoryPurchases.indexWhere((p) => p.id == purchase.id);
    if (idx != -1) {
      _memoryPurchases[idx] = purchase;
    } else {
      _memoryPurchases.insert(0, purchase);
    }

    try {
      final db = await database;
      if (db != null) {
        // Asegurar que la tabla exista por si viene de una versión anterior
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableHistory (
            $_colHistoryId            TEXT PRIMARY KEY NOT NULL,
            $_colHistoryPresupuestoId TEXT NOT NULL,
            $_colHistoryNombre        TEXT NOT NULL,
            $_colHistoryTipo          TEXT NOT NULL,
            $_colHistoryTotalUsd      REAL NOT NULL DEFAULT 0.0,
            $_colHistoryTotalBs       REAL NOT NULL DEFAULT 0.0,
            $_colHistoryTasa          REAL NOT NULL DEFAULT 1.0,
            $_colHistoryCant          INTEGER NOT NULL DEFAULT 0,
            $_colHistoryFecha         TEXT NOT NULL,
            $_colHistoryResumen       TEXT DEFAULT '',
            $_colHistoryItemsJson     TEXT DEFAULT '[]'
          )
        ''');

        await db.insert(
          _tableHistory,
          purchase.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al insertar compra en historial: $e');
    }
  }

  /// Obtiene todo el historial de compras ordenado por fecha descendente.
  Future<List<PurchaseHistoryModel>> getAllPurchases() async {
    try {
      final db = await database;
      if (db != null) {
        // Asegurar que la tabla exista
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableHistory (
            $_colHistoryId            TEXT PRIMARY KEY NOT NULL,
            $_colHistoryPresupuestoId TEXT NOT NULL,
            $_colHistoryNombre        TEXT NOT NULL,
            $_colHistoryTipo          TEXT NOT NULL,
            $_colHistoryTotalUsd      REAL NOT NULL DEFAULT 0.0,
            $_colHistoryTotalBs       REAL NOT NULL DEFAULT 0.0,
            $_colHistoryTasa          REAL NOT NULL DEFAULT 1.0,
            $_colHistoryCant          INTEGER NOT NULL DEFAULT 0,
            $_colHistoryFecha         TEXT NOT NULL,
            $_colHistoryResumen       TEXT DEFAULT '',
            $_colHistoryItemsJson     TEXT DEFAULT '[]'
          )
        ''');

        final maps = await db.query(
          _tableHistory,
          orderBy: '$_colHistoryFecha DESC',
        );
        _memoryPurchases.clear();
        _memoryPurchases.addAll(maps.map(PurchaseHistoryModel.fromMap));
        return List.from(_memoryPurchases);
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al obtener historial de compras: $e');
    }
    return List.from(_memoryPurchases);
  }

  /// Elimina un registro de compra del historial por ID.
  Future<void> deletePurchase(String id) async {
    _memoryPurchases.removeWhere((p) => p.id == id);
    try {
      final db = await database;
      if (db != null) {
        await db.delete(
          _tableHistory,
          where: '$_colHistoryId = ?',
          whereArgs: [id],
        );
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al eliminar compra de historial: $e');
    }
  }

  // ── Configuración Clave-Valor ─────────────────────────────────────────────

  /// Obtiene un valor de configuración persistido por su clave.
  Future<String?> getConfig(String clave) async {
    if (_memoryConfig.containsKey(clave)) {
      return _memoryConfig[clave];
    }
    try {
      final db = await database;
      if (db != null) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableConfig (
            $_colConfigClave TEXT PRIMARY KEY NOT NULL,
            $_colConfigValor TEXT NOT NULL
          )
        ''');
        final res = await db.query(
          _tableConfig,
          where: '$_colConfigClave = ?',
          whereArgs: [clave],
          limit: 1,
        );
        if (res.isNotEmpty) {
          final val = res.first[_colConfigValor] as String?;
          if (val != null) _memoryConfig[clave] = val;
          return val;
        }
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al leer config $clave: $e');
    }
    return null;
  }

  /// Guarda o actualiza un valor de configuración persistido.
  Future<void> setConfig(String clave, String valor) async {
    _memoryConfig[clave] = valor;
    try {
      final db = await database;
      if (db != null) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_tableConfig (
            $_colConfigClave TEXT PRIMARY KEY NOT NULL,
            $_colConfigValor TEXT NOT NULL
          )
        ''');
        await db.insert(
          _tableConfig,
          {
            _colConfigClave: clave,
            _colConfigValor: valor,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('[DatabaseHelper] Error al guardar config $clave: $e');
    }
  }

  // ── Utilidades ────────────────────────────────────────────────────────────

  /// Cierra la conexión a la base de datos.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      _database = null;
      await db.close();
    }
  }
}

