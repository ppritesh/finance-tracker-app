class FinanceSummary {
  const FinanceSummary({
    required this.pendingCreditTotal,
    required this.receivedCreditTotal,
    required this.expenseTotalThisMonth,
    required this.expenseTotalAllTime,
  });

  final double pendingCreditTotal;
  final double receivedCreditTotal;
  final double expenseTotalThisMonth;
  final double expenseTotalAllTime;

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSummary(
      pendingCreditTotal: _toDouble(json['pendingCreditTotal']),
      receivedCreditTotal: _toDouble(json['receivedCreditTotal']),
      expenseTotalThisMonth: _toDouble(json['expenseTotalThisMonth']),
      expenseTotalAllTime: _toDouble(json['expenseTotalAllTime']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }
}
