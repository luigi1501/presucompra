import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/sqlite_init.dart';
import 'providers/budget_provider.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  // Asegurar que los bindings de Flutter estén inicializados
  // antes de cualquier llamada a código nativo (SQLite, etc.).
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar SQLite adaptado a la plataforma (Web, Windows, Linux, macOS o Mobile)
  initializeSqlite();

  // Forzar orientación vertical en móviles (Android / iOS)
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Configurar el estilo de la barra de estado para el tema oscuro
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundBase,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const PresuCompraApp());
}

/// Raíz de la aplicación PresuCompra.
///
/// Configura el árbol de Provider y aplica el tema
/// Cyber-Clean Dark / Neón a toda la aplicación.
class PresuCompraApp extends StatelessWidget {
  const PresuCompraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider principal: gestión de lista, tasas y presupuesto
        ChangeNotifierProvider<BudgetProvider>(
          create: (_) => BudgetProvider(),
        ),
      ],
      child: MaterialApp(
        // ── Metadatos ──────────────────────────────────────────────────────
        title: 'PresuCompra',
        debugShowCheckedModeBanner: false,

        // ── Tema ───────────────────────────────────────────────────────────
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,

        // ── Accesibilidad ──────────────────────────────────────────────────
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.9, 1.3),
              ),
            ),
            child: child!,
          );
        },

        // ── Navegación ─────────────────────────────────────────────────────
        home: const HomeScreen(),
      ),
    );
  }
}