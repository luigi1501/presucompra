import 'sqlite_init_stub.dart'
    if (dart.library.io) 'sqlite_init_io.dart'
    if (dart.library.html) 'sqlite_init_web.dart'
    if (dart.library.js_interop) 'sqlite_init_web.dart';

/// Inicializa el soporte de SQLite adecuado para la plataforma
/// en tiempo de ejecución:
/// - En Web: inicializa `sqflite_common_ffi_web` (IndexedDB WASM)
/// - En Desktop (Windows/Linux/macOS): inicializa `sqflite_common_ffi`
/// - En Mobile (Android/iOS): utiliza la implementación nativa directa de `sqflite`
void initializeSqlite() {
  initPlatformSqlite();
}

