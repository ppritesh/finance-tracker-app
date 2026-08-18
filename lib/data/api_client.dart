import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({this.baseUrl = defaultBaseUrl});

  static const defaultBaseUrl = 'https://fintracker.ztox.in/api';
  static const _timeout = Duration(seconds: 20);

  String baseUrl;
  String? token;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _post(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await http
        .post(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(_timeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _put(
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final response = await http
        .put(_uri(path), headers: _headers, body: jsonEncode(body ?? {}))
        .timeout(_timeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    final response = await http
        .get(_uri(path, query), headers: _headers)
        .timeout(_timeout);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final response = await http
        .delete(_uri(path), headers: _headers)
        .timeout(_timeout);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      json = decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      json = {};
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }
    throw ApiException(
      _errorMessage(json, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  String _errorMessage(Map<String, dynamic> json, int status) {
    final errors = json['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
    }
    final message = json['message'];
    if (message is String && message.isNotEmpty) return message;
    return 'Server error ($status). Please try again.';
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) => _post('/auth/register', {
    'name': name,
    'email': email,
    'password': password,
    'password_confirmation': password,
  });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => _post('/auth/login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> verifyTwoFactor({
    required String twoFactorToken,
    required String code,
  }) => _post('/auth/two-factor/verify', {
    'twoFactorToken': twoFactorToken,
    'code': code,
  });

  Future<Map<String, dynamic>> setupTwoFactor() =>
      _post('/auth/two-factor/setup');

  Future<Map<String, dynamic>> confirmTwoFactor({required String code}) =>
      _post('/auth/two-factor/confirm', {'code': code});

  Future<Map<String, dynamic>> disableTwoFactor({
    required String password,
    required String code,
  }) => _post('/auth/two-factor/disable', {
    'password': password,
    'code': code,
  });

  Future<void> logout() => _post('/auth/logout');

  Future<Map<String, dynamic>> fetchUser() => _get('/auth/user');

  Future<Map<String, dynamic>> fetchSummary() => _get('/summary');

  Future<List<Map<String, dynamic>>> fetchPersons({String? query}) async {
    final json = await _get(
      '/persons',
      query != null && query.isNotEmpty ? {'q': query} : null,
    );
    final persons = json['persons'];
    if (persons is! List) return [];
    return persons.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createPerson(Map<String, dynamic> body) =>
      _post('/persons', body);

  Future<Map<String, dynamic>> updatePerson(int id, Map<String, dynamic> body) =>
      _put('/persons/$id', body);

  Future<void> deletePerson(int id) => _delete('/persons/$id');

  Future<List<Map<String, dynamic>>> fetchTransactions({
    String? type,
    String? status,
    int? personId,
  }) async {
    final query = <String, String>{};
    if (type != null) query['type'] = type;
    if (status != null) query['status'] = status;
    if (personId != null) query['person_id'] = '$personId';

    final json = await _get('/transactions', query.isEmpty ? null : query);
    final transactions = json['transactions'];
    if (transactions is! List) return [];
    return transactions.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> body) =>
      _post('/transactions', body);

  Future<Map<String, dynamic>> updateTransaction(
    int id,
    Map<String, dynamic> body,
  ) => _put('/transactions/$id', body);

  Future<void> deleteTransaction(int id) => _delete('/transactions/$id');

  Future<Map<String, dynamic>> recordPayment(
    int id, {
    required double amount,
    required String receivedOn,
    String? receivedNote,
  }) => _post('/transactions/$id/record-payment', {
    'amount': amount,
    'receivedOn': receivedOn,
    if (receivedNote != null && receivedNote.isNotEmpty)
      'receivedNote': receivedNote,
  });

  Future<Map<String, dynamic>> markReceived(
    int id, {
    required String receivedOn,
    String? receivedNote,
  }) => _post('/transactions/$id/mark-received', {
    'receivedOn': receivedOn,
    if (receivedNote != null && receivedNote.isNotEmpty)
      'receivedNote': receivedNote,
  });
}
