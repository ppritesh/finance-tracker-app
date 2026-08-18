import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'secure_storage.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.api, {SecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorage();

  static const _nameKey = 'auth_user_name';
  static const _emailKey = 'auth_user_email';
  static const _twoFactorKey = 'auth_two_factor_enabled';

  final ApiClient api;
  final SecureStorage _secureStorage;

  bool _loaded = false;
  String? _userName;
  String? _userEmail;
  bool _twoFactorEnabled = false;
  String? _pendingTwoFactorToken;
  String? _pendingUserName;
  String? _pendingUserEmail;

  bool get isLoaded => _loaded;
  bool get isAuthenticated => api.token != null;
  bool get needsTwoFactor => _pendingTwoFactorToken != null;
  bool get twoFactorEnabled => _twoFactorEnabled;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get pendingUserName => _pendingUserName;
  String? get pendingUserEmail => _pendingUserEmail;

  Future<void> load() async {
    api.token = await _secureStorage.readToken();
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString(_nameKey);
    _userEmail = prefs.getString(_emailKey);
    _twoFactorEnabled = prefs.getBool(_twoFactorKey) ?? false;
    _loaded = true;
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
    if (result['requiresTwoFactor'] == true) {
      _pendingTwoFactorToken = result['twoFactorToken'] as String?;
      final user = (result['user'] as Map<String, dynamic>?) ?? {};
      _pendingUserName = user['name'] as String?;
      _pendingUserEmail = user['email'] as String?;
      notifyListeners();
      return;
    }
    await _storeSession(result);
  }

  Future<void> verifyTwoFactor(String code) async {
    final token = _pendingTwoFactorToken;
    if (token == null) {
      throw Exception('No pending authenticator challenge.');
    }

    final result = await api.verifyTwoFactor(
      twoFactorToken: token,
      code: code,
    );
    _pendingTwoFactorToken = null;
    _pendingUserName = null;
    _pendingUserEmail = null;
    await _storeSession(result);
  }

  void cancelTwoFactor() {
    _pendingTwoFactorToken = null;
    _pendingUserName = null;
    _pendingUserEmail = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> beginTwoFactorSetup() => api.setupTwoFactor();

  Future<void> confirmTwoFactorSetup(String code) async {
    final result = await api.confirmTwoFactor(code: code);
    await _updateUserFlags(result);
  }

  Future<void> disableTwoFactor({
    required String password,
    required String code,
  }) async {
    final result = await api.disableTwoFactor(password: password, code: code);
    await _updateUserFlags(result);
  }

  Future<void> refreshUser() async {
    final result = await api.fetchUser();
    await _updateUserFlags(result);
  }

  Future<void> signOut() async {
    try {
      await api.logout();
    } catch (_) {}
    api.token = null;
    _userName = null;
    _userEmail = null;
    _twoFactorEnabled = false;
    _pendingTwoFactorToken = null;
    _pendingUserName = null;
    _pendingUserEmail = null;
    await _secureStorage.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_twoFactorKey);
    notifyListeners();
  }

  Future<void> _storeSession(Map<String, dynamic> result) async {
    final user = (result['user'] as Map<String, dynamic>?) ?? {};
    api.token = result['token'] as String?;
    _userName = user['name'] as String?;
    _userEmail = user['email'] as String?;
    _twoFactorEnabled = user['twoFactorEnabled'] == true;
    if (api.token != null) {
      await _secureStorage.writeToken(api.token!);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, _userName ?? '');
    await prefs.setString(_emailKey, _userEmail ?? '');
    await prefs.setBool(_twoFactorKey, _twoFactorEnabled);
    notifyListeners();
  }

  Future<void> _updateUserFlags(Map<String, dynamic> result) async {
    final user = (result['user'] as Map<String, dynamic>?) ?? {};
    _userName = user['name'] as String? ?? _userName;
    _userEmail = user['email'] as String? ?? _userEmail;
    _twoFactorEnabled = user['twoFactorEnabled'] == true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, _userName ?? '');
    await prefs.setString(_emailKey, _userEmail ?? '');
    await prefs.setBool(_twoFactorKey, _twoFactorEnabled);
    notifyListeners();
  }
}
