import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Loader animado personalizado de PresuCompra.
///
/// Reemplaza el clásico círculo giratorio:
/// Muestra un carrito de compras neón con una moneda de dólar ($)
/// que cae desde arriba, rebota dentro del carrito y emite un destello neón.
class CyberCartLoader extends StatefulWidget {
  /// Tamaño base del carrito (por defecto 64).
  final double size;

  /// Texto descriptivo opcional debajo de la animación.
  final String? message;

  /// Si es true, muestra una versión compacta apta para botones o barras.
  final bool isCompact;

  const CyberCartLoader({
    super.key,
    this.size = 64.0,
    this.message,
    this.isCompact = false,
  });

  /// Versión pequeña de 22px para colocar dentro de botones.
  const CyberCartLoader.button({
    super.key,
    this.size = 22.0,
    this.message,
  }) : isCompact = true;

  @override
  State<CyberCartLoader> createState() => _CyberCartLoaderState();
}

class _CyberCartLoaderState extends State<CyberCartLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dropAnimation;
  late Animation<double> _cartBounceAnimation;
  late Animation<double> _coinOpacityAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // 1. Caída de la moneda (0% al 55% del ciclo)
    _dropAnimation = Tween<double>(begin: -1.4, end: 0.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.bounceOut),
      ),
    );

    // 2. Opacidad de la moneda (aparece rápido, se desvanece al final)
    _coinOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 25),
    ]).animate(_controller);

    // 3. Rebote/reacción del carrito al recibir la moneda (50% al 75%)
    _cartBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 12),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.94), weight: 8),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20),
    ]).animate(_controller);

    // 4. Pulso de resplandor neón en el carrito
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 18.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 18.0, end: 4.0), weight: 40),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartSize = widget.size;
    final coinSize = cartSize * 0.38;

    return FittedBox(
      fit: BoxFit.contain,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: cartSize * 1.5,
          height: cartSize * 1.6,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ── Carrito con rebote y resplandor neón ──────────────────
                  Positioned(
                    bottom: 0,
                    child: Transform.scale(
                      scale: _cartBounceAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withAlpha(
                                (80 * (_glowAnimation.value / 18)).toInt(),
                              ),
                              blurRadius: _glowAnimation.value,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shopping_cart_rounded,
                          size: cartSize,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                  ),

                  // ── Moneda de Dólar ($) que cae y rebota ──────────────────
                  Positioned(
                    top: (cartSize * 0.7) +
                        (_dropAnimation.value * cartSize * 0.9),
                    child: Opacity(
                      opacity: _coinOpacityAnimation.value.clamp(0.0, 1.0),
                      child: Transform.rotate(
                        angle: math.sin(_controller.value * math.pi * 2) * 0.15,
                        child: Container(
                          width: coinSize,
                          height: coinSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF34D399), // Verde brillante
                                AppColors.brand,   // Verde esmeralda
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFFA7F3D0),
                              width: widget.isCompact ? 1.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brand.withAlpha(150),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '\$',
                              style: TextStyle(
                                color: AppColors.backgroundBase,
                                fontSize: coinSize * 0.72,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // ── Mensaje opcional debajo ─────────────────────────────────────────
        if (widget.message != null && !widget.isCompact) ...[
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final opacity = 0.6 +
                  (math.sin(_controller.value * math.pi * 2).abs() * 0.4);
              return Text(
                widget.message!,
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(opacity),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              );
            },
          ),
        ],
      ],
    ),
  );
  }
}

