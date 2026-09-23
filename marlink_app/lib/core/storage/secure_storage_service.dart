import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const String _authTokenKey = 'marlink_auth_token';
  static const String _savedUserIdKey = 'marlink_saved_user_id';
  static const String _serverIpKey = 'marlink_server_ip';
  static const String _serverPortKey = 'marlink_server_port';

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _authTokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  Future<void> clearAuthToken() async {
    await _storage.delete(key: _authTokenKey);
  }

  Future<void> saveUserId(int id) async {
    await _storage.write(key: _savedUserIdKey, value: id.toString());
  }

  Future<int?> getUserId() async {
    final str = await _storage.read(key: _savedUserIdKey);
    return str != null ? int.tryParse(str) : null;
  }

  Future<void> saveServerConfig(String ip, int port) async {
    await _storage.write(key: _serverIpKey, value: ip.trim());
    await _storage.write(key: _serverPortKey, value: port.toString());
  }

  Future<String?> getServerIp() async {
    return await _storage.read(key: _serverIpKey);
  }

  Future<int?> getServerPort() async {
    final str = await _storage.read(key: _serverPortKey);
    return str != null ? int.tryParse(str) : null;
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
