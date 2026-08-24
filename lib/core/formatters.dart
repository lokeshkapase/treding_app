import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

import 'money.dart';

class AppFormatters {
  AppFormatters._();

  static final _timeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String price(Decimal value) => Money.format(value);

  static String signedChange(Decimal change) {
    final prefix = change >= Decimal.zero ? '+' : '';
    return '$prefix${Money.formatPlain(change)}';
  }

  static String signedPercent(Decimal percent) {
    final prefix = percent >= Decimal.zero ? '+' : '';
    return '$prefix${percent.toStringAsFixed(2)}%';
  }

  static String quantity(Decimal qty) {
    if (qty == qty.truncate()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  static String dateTime(DateTime dt) => _timeFormat.format(dt);
}
