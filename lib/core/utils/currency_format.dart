/// Utilidades de formato monetario a prueba de fallos para USD y Bolívares.
///
/// Implementación pura en Dart que garantiza:
/// 1. Cero dependencias de locales externas del navegador.
/// 2. Cero posibilidad de excepciones como 'NoSuchMethodError: isNegative'.
/// 3. Soporte seguro para valores nulos, NaN o infinitos.
class CurrencyFormat {
  CurrencyFormat._();

  /// Formatea un monto en dólares estadounidenses (ej: "$12.50", "$1,250.00").
  static String formatUsd(num? value) {
    if (value == null || value.isNaN || value.isInfinite) {
      return '\$0.00';
    }
    final isNeg = value < 0;
    final absVal = value.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    final length = integerPart.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    final prefix = isNeg ? '-\$' : '\$';
    return '$prefix$buffer.$decimalPart';
  }

  /// Formatea un monto en bolívares con formato venezolano:
  /// punto (.) para miles y coma (,) para decimales (ej: "896,12", "1.250,00").
  static String formatBs(num? value) {
    if (value == null || value.isNaN || value.isInfinite) {
      return '0,00';
    }
    final isNeg = value < 0;
    final absVal = value.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    final length = integerPart.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }

    final sign = isNeg ? '-' : '';
    return '$sign$buffer,$decimalPart';
  }

  /// Formatea la tasa de cambio con sufijo Bs. (ej: "896,12 Bs.").
  static String formatRate(num? value) {
    return '${formatBs(value)} Bs.';
  }
}
