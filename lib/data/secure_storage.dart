import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores auth secrets in the platform secure vault (Keychain / Keystore / WebCrypto).
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<void> clear() => _storage.deleteAll();
}
