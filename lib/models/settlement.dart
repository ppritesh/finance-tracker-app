import '../utils/currency_formatter.dart';

class Settlement {
  const Settlement({
    required this.id,
    required this.amount,
    required this.receivedOn,
    this.note,
  });

  final int id;
  final double amount;
  final DateTime receivedOn;
  final String? note;

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id'] as int,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      receivedOn:
          parseApiDate(json['receivedOn'] as String?) ?? DateTime.now(),
      note: json['note'] as String?,
    );
  }
}
