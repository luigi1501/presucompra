import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_format.dart';
import '../../../providers/budget_provider.dart';
import 'create_budget_modal.dart';

/// Modal interactivo de bienvenida y tour guiado para nuevos usuarios.
///
/// Explica las 4 funciones clave diseñadas para la realidad venezolana:
/// 1. Economía bimonetaria (\$ USD y Bolívares con tasa BCV en tiempo real).
/// 2. Fondos globales y presupuestos múltiples por categorías.
/// 3. Calculadora de caja para pago mixto (Efectivo \$ + Pago Móvil Bs.) y vuelto.
/// 4. Memoria inteligente de precios vs. compras anteriores e historial de recibos.
class OnboardingTourModal extends StatefulWidget {
  final bool abrirCrearPresupuestoAlFinalizar;

  const OnboardingTourModal({
    super.key,
    this.abrirCrearPresupuestoAlFinalizar = false,
  });

  /// Muestra el modal de tour de forma responsiva.
  static Future<void> show(
    BuildContext context, {
    bool abrirCrearPresupuestoAlFinalizar = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
          child: OnboardingTourModal(
            abrirCrearPresupuestoAlFinalizar: abrirCrearPresupuestoAlFinalizar,
          ),
        ),
      ),
    );
  }

  @override
  State<OnboardingTourModal> createState() => _OnboardingTourModalState();
}

class _OnboardingTourModalState extends State<OnboardingTourModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFinish() {
    HapticFeedback.mediumImpact();
    final provider = context.read<BudgetProvider>();
    provider.marcarTourVisto();
    Navigator.of(context).pop();

    if (widget.abrirCrearPresupuestoAlFinalizar && !provider.tienePresupuestos) {
      CreateBudgetModal.show(context);
    }
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onFinish();
    }
  }

  void _prevPage() {
    HapticFeedback.lightImpact();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasa = context.select<BudgetProvider, double>((p) => p.tasaBsUsd);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundBase,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withAlpha(40),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Barra Superior (Paso actual y botón Saltar) ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.brand.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.explore_rounded,
                          size: 14, color: AppColors.brand),
                      const SizedBox(width: 5),
                      Text(
                        'TOUR GUIADO • ${_currentPage + 1} DE $_totalPages',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _onFinish,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text(
                    'Saltar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.cardBorder, height: 1),

          // ── Contenido de las Diapositivas (PageView) ──────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              children: [
                _buildSlide1Bimoneda(tasa),
                _buildSlide2Presupuestos(),
                _buildSlide3CalculadoraCaja(),
                _buildSlide4MemoriaEHistorial(),
              ],
            ),
          ),

          const Divider(color: AppColors.cardBorder, height: 1),

          // ── Barra Inferior (Indicador de puntos y botones de acción) ───────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón Anterior (solo si no es la primera)
                if (_currentPage > 0)
                  TextButton.icon(
                    onPressed: _prevPage,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Atrás'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  )
                else
                  const SizedBox(width: 70),

                // Indicador de puntos (Dots)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_totalPages, (index) {
                    final isCurrent = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isCurrent ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.brand
                            : AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.brand.withAlpha(120),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                // Botón Siguiente / ¡Comenzar!
                ElevatedButton.icon(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: AppColors.backgroundBase,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: Icon(
                    _currentPage == _totalPages - 1
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _currentPage == _totalPages - 1 ? '¡Comenzar!' : 'Siguiente',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Slide 1: Bimoneda (\$ / Bs.) y Tasa BCV ─────────────────────────────────
  Widget _buildSlide1Bimoneda(double tasa) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          _buildIconCircle(
            icon: Icons.currency_exchange_rounded,
            color: AppColors.brand,
          ),
          const SizedBox(height: 18),
          const Text(
            'Control Bimonetario Total',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pensada 100% para la realidad económica venezolana',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Olvídate de calcular mentalmente al recorrer los pasillos. Cada producto muestra su valor en \$ USD y en Bolívares sincronizados con la tasa oficial.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            leadingIcon: Icons.bolt_rounded,
            title: 'Tasa BCV Oficial en Tiempo Real',
            subtitle:
                'Tasa activa hoy: ${CurrencyFormat.formatRate(tasa)}. Puedes refrescarla en un toque o colocar tu propia tasa si lo prefieres.',
            accentColor: AppColors.brand,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            leadingIcon: Icons.toggle_on_rounded,
            title: 'Entrada Flexible de Precios',
            subtitle:
                'Ingresa precios en Bolívares o Dólares según los veas en los anaqueles. La conversión se hace al instante.',
            accentColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  // ── Slide 2: Presupuestos y Listas Múltiples ───────────────────────────────
  Widget _buildSlide2Presupuestos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          _buildIconCircle(
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.accent,
          ),
          const SizedBox(height: 18),
          const Text(
            'Presupuestos y Listas Separadas',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Separa tus compras y nunca te pases de tu límite',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Crea listas independientes para el Mercado, Estudios de los chamos, Gastos Personales o Farmacia, cada una con su propio tope asignado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            leadingIcon: Icons.account_balance_rounded,
            title: '🏛️ Fondo Global / Presupuesto Principal',
            subtitle:
                'Fija tu fondo total del mes (ej: \$300) y monitorea el porcentaje asignado y gastado en cada lista.',
            accentColor: AppColors.accent,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            leadingIcon: Icons.pie_chart_outline_rounded,
            title: '📊 Distribución Visual de Fondos',
            subtitle:
                'Accede al gráfico comparativo para ver de un vistazo qué porcentaje de tu dinero va para alimentos, estudios u otros gastos.',
            accentColor: AppColors.brand,
          ),
        ],
      ),
    );
  }

  // ── Slide 3: Calculadora de Caja (Pago Mixto) ──────────────────────────────
  Widget _buildSlide3CalculadoraCaja() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          _buildIconCircle(
            icon: Icons.point_of_sale_rounded,
            color: AppColors.brand,
          ),
          const SizedBox(height: 18),
          const Text(
            'Calculadora de Caja y Vuelto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cero dolores de cabeza al momento de pagar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '¿Pagarás \$20 en efectivo y el resto por Pago Móvil o Punto? La calculadora te dice el restante exacto en Bolívares o cuánto vuelto te corresponde.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            leadingIcon: Icons.attach_money_rounded,
            title: 'Billetes Rápidos en USD',
            subtitle:
                'Toca botones directos de \$5, \$10, \$20, \$50 o \$100 sin tener que tipear el monto del efectivo.',
            accentColor: AppColors.brand,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            leadingIcon: Icons.phonelink_ring_rounded,
            title: 'Botón "Pagar Restante Exacto"',
            subtitle:
                'Con 1 toque completa los Bolívares restantes en tu Pago Móvil y copia el monto al portapapeles para transferir.',
            accentColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  // ── Slide 4: Memoria de Precios e Historial ─────────────────────────────────
  Widget _buildSlide4MemoriaEHistorial() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          _buildIconCircle(
            icon: Icons.auto_awesome_rounded,
            color: AppColors.brandGlow,
          ),
          const SizedBox(height: 18),
          const Text(
            'Memoria de Precios e Historial',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aprende de tus compras y detecta la inflación',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.brandGlow,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Al escribir el nombre de un producto, la app te sugiere el precio que pagaste antes y te alerta si el nuevo precio está más caro o más barato.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          _buildFeatureCard(
            leadingIcon: Icons.insights_rounded,
            title: 'Autocompletado con Último Precio',
            subtitle:
                'Toca el chip de sugerencia para cargar al instante nombre, categoría y precio anterior del producto.',
            accentColor: AppColors.brandGlow,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            leadingIcon: Icons.receipt_long_rounded,
            title: 'Finalizar Compra y Archivo',
            subtitle:
                'Al salir de la tienda, pulsa "Finalizar Compra" desde el menú para archivar un recibo digital con fecha, tasa y detalle de artículos.',
            accentColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  // ── Componentes de Diseño ──────────────────────────────────────────────────

  Widget _buildIconCircle({required IconData icon, required Color color}) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(120), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 36),
    );
  }

  Widget _buildFeatureCard({
    required IconData leadingIcon,
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(leadingIcon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

