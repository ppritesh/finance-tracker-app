import '../utils/currency_formatter.dart';

enum TransactionType { creditGiven, expense }

enum TransactionStatus { pending, received, paid }

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
    TransactionStatus.received => 'Received',
    TransactionStatus.paid => 'Paid',
  };

  static TransactionStatus fromApi(String value) => switch (value) {
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
    required this.transactionDate,
    required this.status,
    this.receivedOn,
    this.receivedNote,
  });

  final int id;
  final TransactionType type;
  final int? personId;
  final String? personName;
  final String? note;
  final double amount;
  final DateTime transactionDate;
  final TransactionStatus status;
  final DateTime? receivedOn;
  final String? receivedNote;

  bool get isPendingCredit =>
      type == TransactionType.creditGiven && status == TransactionStatus.pending;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      type: TransactionTypeX.fromApi(json['type'] as String? ?? ''),
      personId: json['personId'] as int?,
      personName: json['personName'] as String?,
      note: json['note'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      transactionDate:
          parseApiDate(json['transactionDate'] as String?) ?? DateTime.now(),
      status: TransactionStatusX.fromApi(json['status'] as String? ?? ''),
      receivedOn: parseApiDate(json['receivedOn'] as String?),
      receivedNote: json['receivedNote'] as String?,
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
