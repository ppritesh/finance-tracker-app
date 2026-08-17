import 'package:flutter/foundation.dart';

import '../models/person.dart';
import '../models/summary.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import 'api_client.dart';
import 'auth_controller.dart';

class FinanceRepository extends ChangeNotifier {
  FinanceRepository({required this.api, required this.auth});

  final ApiClient api;
  final AuthController auth;

  bool _loaded = false;
  bool _loading = false;
  String? _error;
  FinanceSummary? _summary;
  List<Transaction> _transactions = [];
  List<Person> _persons = [];

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;
  String? get error => _error;
  FinanceSummary? get summary => _summary;
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Person> get persons => List.unmodifiable(_persons);

  Future<void> refreshAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([refreshSummary(), refreshTransactions(), refreshPersons()]);
      _loaded = true;
    } on ApiException catch (e) {
      _handleApiError(e);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSummary() async {
    final json = await api.fetchSummary();
    _summary = FinanceSummary.fromJson(json);
  }

  Future<void> refreshTransactions({
    TransactionType? type,
    TransactionStatus? status,
  }) async {
    final rows = await api.fetchTransactions(
      type: type?.apiValue,
      status: status?.apiValue,
    );
    _transactions = rows.map(Transaction.fromJson).toList();
  }

  Future<void> refreshPersons({String? query}) async {
    final rows = await api.fetchPersons(query: query);
    _persons = rows.map(Person.fromJson).toList();
  }

  Future<Transaction> createTransaction(Transaction draft) async {
    final json = await api.createTransaction(draft.toJson());
    final created = Transaction.fromJson(
      json['transaction'] as Map<String, dynamic>,
    );
    await refreshAll();
    return created;
  }

  Future<Transaction> updateTransaction(Transaction draft) async {
    final json = await api.updateTransaction(draft.id, draft.toJson());
    final updated = Transaction.fromJson(
      json['transaction'] as Map<String, dynamic>,
    );
    await refreshAll();
    return updated;
  }

  Future<void> deleteTransaction(int id) async {
    await api.deleteTransaction(id);
    await refreshAll();
  }

  Future<Transaction> markReceived(
    int id, {
    required DateTime receivedOn,
    String? receivedNote,
  }) async {
    final json = await api.markReceived(
      id,
      receivedOn: formatApiDate(receivedOn),
      receivedNote: receivedNote,
    );
    final updated = Transaction.fromJson(
      json['transaction'] as Map<String, dynamic>,
    );
    await refreshAll();
    return updated;
  }

  Future<Person> createPerson({required String name, String? phone}) async {
    final json = await api.createPerson({
      'name': name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final created = Person.fromJson(json['person'] as Map<String, dynamic>);
    await refreshPersons();
    notifyListeners();
    return created;
  }

  Future<Person> updatePerson(Person person) async {
    final json = await api.updatePerson(person.id, person.toJson());
    final updated = Person.fromJson(json['person'] as Map<String, dynamic>);
    await refreshPersons();
    notifyListeners();
    return updated;
  }

  Future<void> deletePerson(int id) async {
    await api.deletePerson(id);
    await refreshPersons();
    notifyListeners();
  }

  void _handleApiError(ApiException e) {
    _error = e.message;
    if (e.isUnauthorized) {
      auth.signOut();
    }
  }
}