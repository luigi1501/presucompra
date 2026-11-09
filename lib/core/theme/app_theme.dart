import 'package:flutter/material.dart';

/// PresuCompra — Cyber-Clean Dark / Neón Theme
///
/// Paleta basada en el logo oficial:
///  • Verde Esmeralda Neón (#10B981) → color dominante / identidad de marca
///  • Cyan Neón (#06B6D4)            → color de acento / acciones secundarias
///  • Fondo negro profundo (#000000 → #0F172A) → ambiente del logo
class AppColors {
  AppColors._();

  // ── Fondos ────────────────────────────────────────────────────────────────
  static const Color backgroundBase = Color(0xFF050D1A); // Negro-Azul profundo (como el logo)
  static const Color cardSurface = Color(0xFF0F1F35); // Superficie oscura
  static const Color cardBorder = Color(0xFF1E3A5F); // Borde azul-oscuro sutil

  // ── Identidad de Marca (del logo) ─────────────────────────────────────────
  /// Verde Neón — color dominante del logo, carrito + glow circular
  static const Color brand = Color(0xFF10B981);       // Verde Esmeralda Neón
  static const Color brandGlow = Color(0xFF34D399);   // Verde más brillante para glow
  static const Color brandDark = Color(0xFF065F46);   // Verde oscuro para contenedores

  // ── Semánticos ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF10B981);  // Verde (=brand) — color principal UI
  static const Color accent = Color(0xFF06B6D4);   // Cyan Neón — acento/secundario
  static const Color success = Color(0xFF10B981);  // Verde — presupuesto OK
  static const Color danger = Color(0xFFEF4444);   // Rojo Carmesí — exceso
  static const Color warning = Color(0xFFF59E0B);  // Ámbar — zona de alerta

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);   // Blanco Puro
  static const Color textSecondary = Color(0xFF94A3B8); // Gris Slate 400
  static const Color textDisabled = Color(0xFF475569);  // Slate 600

  // ── Categorías ────────────────────────────────────────────────────────────
  static const Color catAlimentos  = Color(0xFF84CC16); // Lima
  static const Color catHigiene    = Color(0xFF38BDF8); // Sky Claro
  static const Color catFarmacia   = Color(0xFFF472B6); // Rosa
  static const Color catCosmeticos = Color(0xFFA78BFA); // Violeta
  static const Color catTecnologia = Color(0xFFFBBF24); // Ámbar
  static const Color catPapeleria  = Color(0xFF60A5FA); // Azul Claro
  static const Color catTransporte = Color(0xFFFB923C); // Naranja
  static const Color catRestaurante= Color(0xFFFF6B6B); // Rojo Suave
  static const Color catOtros      = Color(0xFF94A3B8); // Gris Slate
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      // Verde Neón (brand) como color primario — fiel al logo
      primary: AppColors.brand,
      onPrimary: AppColors.backgroundBase,
      primaryContainer: AppColors.brandDark,
      onPrimaryContainer: AppColors.brandGlow,
      // Cyan como color secundario / acento
      secondary: AppColors.accent,
      onSecondary: AppColors.backgroundBase,
      secondaryContainer: Color(0xFF164E63),
      onSecondaryContainer: AppColors.accent,
      error: AppColors.danger,
      onError: AppColors.textPrimary,
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: AppColors.danger,
      surface: AppColors.cardSurface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.cardBorder,
      outlineVariant: Color(0xFF0F2744),
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.backgroundBase,
      inversePrimary: AppColors.brandDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundBase,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundBase,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5, // Tipografía espaciada como en el logo
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Tipografía ────────────────────────────────────────────────────────
      textTheme: const TextTheme(
        // Pantallas / Totales grandes
        displayLarge: TextStyle(
          color: AppColors.success,
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
        displayMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        // Títulos de sección
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        // Títulos de card/tile
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        titleSmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        // Cuerpo
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: AppColors.textDisabled,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        // Labels
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          color: AppColors.textDisabled,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),

      // ── Botones ───────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.backgroundBase,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brand, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: AppColors.backgroundBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: AppColors.backgroundBase,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ── Input ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundBase,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
      ),

      // ── Checkbox ──────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) return AppColors.brand;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.backgroundBase),
        side: const BorderSide(color: AppColors.brand, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Slider ────────────────────────────────────────────────────────────
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.cardBorder,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x2006B6D4),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: AppColors.cardBorder,
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cardSurface,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundBase,
        selectedColor: AppColors.primary.withAlpha(30),
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        side: const BorderSide(color: AppColors.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.cardBorder,
        linearMinHeight: 12,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),

      // ── Icon ──────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}

