import '../models/person.dart';
import '../models/person_summary.dart';
import '../models/transaction.dart';

List<PersonSummary> buildPersonSummaries({
  required List<Person> persons,
  required List<Transaction> transactions,
}) {
  final credits = transactions
      .where((t) => t.type == TransactionType.creditGiven && t.personId != null);

  final byPersonId = <int, List<Transaction>>{};
  for (final tx in credits) {
    byPersonId.putIfAbsent(tx.personId!, () => []).add(tx);
  }

  final summaries = persons.map((person) {
    final personCredits = byPersonId[person.id] ?? [];
    final totalCredit = personCredits.fold<double>(0, (s, t) => s + t.amount);
    final totalReceived = personCredits.fold<double>(
      0,
      (s, t) => s + t.receivedTotal,
    );
    final totalRemaining = personCredits.fold<double>(
      0,
      (s, t) => s + t.remainingAmount,
    );

    return PersonSummary(
      personId: person.id,
      name: person.name,
      phone: person.phone,
      totalCredit: totalCredit,
      totalReceived: totalReceived,
      totalRemaining: totalRemaining,
      creditCount: personCredits.length,
    );
  }).toList();

  summaries.sort((a, b) {
    if (a.totalRemaining != b.totalRemaining) {
      return b.totalRemaining.compareTo(a.totalRemaining);
    }
    return a.name.compareTo(b.name);
  });

  return summaries;
}

List<Transaction> transactionsForPerson(
  List<Transaction> transactions,
  int personId,
) {
  return transactions
      .where((t) => t.personId == personId)
      .toList()
    ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
}

Map<String, List<Transaction>> groupCreditTransactionsByPerson(
  List<Transaction> transactions,
) {
  final grouped = <String, List<Transaction>>{};

  for (final tx in transactions) {
    if (tx.type != TransactionType.creditGiven) continue;
    final key = tx.personName ?? 'Unknown';
    grouped.putIfAbsent(key, () => []).add(tx);
  }

  final sortedKeys = grouped.keys.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return {for (final key in sortedKeys) key: grouped[key]!};
}
