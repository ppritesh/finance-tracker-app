class PersonSummary {
  const PersonSummary({
    required this.personId,
    required this.name,
    this.phone,
    required this.totalCredit,
    required this.totalReceived,
    required this.totalRemaining,
    required this.creditCount,
  });

  final int personId;
  final String name;
  final String? phone;
  final double totalCredit;
  final double totalReceived;
  final double totalRemaining;
  final int creditCount;

  bool get hasCredit => creditCount > 0;
}
