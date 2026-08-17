import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.api);

  static const _tokenKey = 'auth_token';
  static const _nameKey = 'auth_user_name';
  static const _emailKey = 'auth_user_email';
  static const _serverKey = 'server_url';

  final ApiClient api;

  bool _loaded = false;
  String? _userName;
  String? _userEmail;

  bool get isLoaded => _loaded;
  bool get isAuthenticated => api.token != null;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String get serverUrl => api.baseUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    api.token = prefs.getString(_tokenKey);
    api.baseUrl = prefs.getString(_serverKey) ?? ApiClient.defaultBaseUrl;
    _userName = prefs.getString(_nameKey);
    _userEmail = prefs.getString(_emailKey);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setServerUrl(String url) async {
    final trimmed = url.trim().replaceAll(RegExp(r'/+$'), '');
    api.baseUrl = trimmed.isEmpty ? ApiClient.defaultBaseUrl : trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverKey, api.baseUrl);
    notifyListeners();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await api.register(
      name: name,
      email: email,
      password: password,
    );
    await _storeSession(result);
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final result = await api.login(email: email, password: password);
    await _storeSession(result);
  }

  Future<void> signOut() async {
    try {
      await api.logout();
    } catch (_) {}
    api.token = null;
    _userName = null;
    _userEmail = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    notifyListeners();
  }

  Future<void> _storeSession(Map<String, dynamic> result) async {
    final user = (result['user'] as Map<String, dynamic>?) ?? {};
    api.token = result['token'] as String?;
    _userName = user['name'] as String?;
    _userEmail = user['email'] as String?;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, api.token ?? '');
    await prefs.setString(_nameKey, _userName ?? '');
    await prefs.setString(_emailKey, _userEmail ?? '');
    notifyListeners();
  }
}
