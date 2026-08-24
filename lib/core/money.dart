import 'package:decimal/decimal.dart';
import 'package:rational/rational.dart';

/// Precise money/decimal helpers — all user-visible amounts use 2 decimal places.
class Money {
  Money._();

  static Decimal parse(String value) => Decimal.parse(value);

  static Decimal fromNum(num value) =>
      Decimal.parse(value.toStringAsFixed(2));

  static String format(Decimal value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    var count = 0;
    for (var i = intPart.length - 1; i >= 0; i--) {
      if (count == 3) {
        buffer.write(',');
        count = 0;
      }
      buffer.write(intPart[i]);
      count++;
    }
    final formattedInt = buffer.toString().split('').reversed.join();
    return '₹$formattedInt.${parts[1]}';
  }

  static String formatPlain(Decimal value) => value.toStringAsFixed(2);

  static Decimal multiply(Decimal a, Decimal b) => a * b;

  static Decimal divide(Decimal a, Decimal b) => (a / b).toDecimal(
        scaleOnInfinitePrecision: 10,
      );

  static Decimal percentChange(Decimal change, Decimal base) {
    if (base == Decimal.zero) return Decimal.zero;
    return (change / base * Rational.fromInt(100)).toDecimal(
      scaleOnInfinitePrecision: 10,
    );
  }
}
