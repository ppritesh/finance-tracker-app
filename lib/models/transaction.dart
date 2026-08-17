import '../utils/currency_formatter.dart';
import 'settlement.dart';

enum TransactionType { creditGiven, expense }

enum TransactionStatus { pending, partial, received, paid }

extension TransactionTypeX on TransactionType {
  String get apiValue => switch (this) {
    TransactionType.creditGiven => 'credit_given',
    TransactionType.expense => 'expense',
  };

  String get label => switch (this) {
    TransactionType.creditGiven => 'Credit Given',
    TransactionType.expense => 'Expense',
  };

  static TransactionType fromApi(String value) => switch (value) {
    'expense' => TransactionType.expense,
    _ => TransactionType.creditGiven,
  };
}

extension TransactionStatusX on TransactionStatus {
  String get apiValue => name;

  String get label => switch (this) {
    TransactionStatus.pending => 'Pending',
    TransactionStatus.partial => 'Partial',
    TransactionStatus.received => 'Received',
    TransactionStatus.paid => 'Paid',
  };

  static TransactionStatus fromApi(String value) => switch (value) {
    'partial' => TransactionStatus.partial,
    'received' => TransactionStatus.received,
    'paid' => TransactionStatus.paid,
    _ => TransactionStatus.pending,
  };
}

class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    this.personId,
    this.personName,
    this.note,
    required this.amount,
    this.receivedTotal = 0,
    this.remainingAmount = 0,
    required this.transactionDate,
    required this.status,
    this.receivedOn,
    this.receivedNote,
    this.settlements = const [],
  });

  final int id;
  final TransactionType type;
  final int? personId;
  final String? personName;
  final String? note;
  final double amount;
  final double receivedTotal;
  final double remainingAmount;
  final DateTime transactionDate;
  final TransactionStatus status;
  final DateTime? receivedOn;
  final String? receivedNote;
  final List<Settlement> settlements;

  bool get canRecordPayment =>
      type == TransactionType.creditGiven &&
      (status == TransactionStatus.pending ||
          status == TransactionStatus.partial);

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final settlementsJson = json['settlements'];
    final settlements = settlementsJson is List
        ? settlementsJson
              .whereType<Map<String, dynamic>>()
              .map(Settlement.fromJson)
              .toList()
        : <Settlement>[];

    return Transaction(
      id: json['id'] as int,
      type: TransactionTypeX.fromApi(json['type'] as String? ?? ''),
      personId: json['personId'] as int?,
      personName: json['personName'] as String?,
      note: json['note'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      receivedTotal: (json['receivedTotal'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remainingAmount'] as num?)?.toDouble() ?? 0,
      transactionDate:
          parseApiDate(json['transactionDate'] as String?) ?? DateTime.now(),
      status: TransactionStatusX.fromApi(json['status'] as String? ?? ''),
      receivedOn: parseApiDate(json['receivedOn'] as String?),
      receivedNote: json['receivedNote'] as String?,
      settlements: settlements,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.apiValue,
    if (personId != null) 'personId': personId,
    if (note != null && note!.isNotEmpty) 'note': note,
    'amount': amount,
    'transactionDate': formatApiDate(transactionDate),
  };
}
