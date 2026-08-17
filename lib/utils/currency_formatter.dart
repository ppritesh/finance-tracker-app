import 'package:intl/intl.dart';

final _inrFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
);

String formatInr(num amount) => _inrFormat.format(amount);

String formatDate(DateTime date) => DateFormat.yMMMd().format(date);

String formatApiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

DateTime? parseApiDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
