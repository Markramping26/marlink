import '../storage/secure_storage_service.dart';

class AppConfig {
  AppConfig._();

  /// Set this to your live production domain or cloud URL when hosting online:
  static const String productionServerUrl = 'https://marlink-api.onrender.com';

  // Current machine Wi-Fi IP on local network (for local development)
  static const String defaultServerHostIp = '192.168.4.43';
  static const int defaultServerPort = 8000;

  static String serverHostIp = defaultServerHostIp;
  static int serverPort = defaultServerPort;

  static String _buildBaseUrl(String host, int port) {
    if (productionServerUrl.trim().isNotEmpty) {
      final clean = productionServerUrl.trim().replaceAll(RegExp(r'/+$'), '');
      return clean.endsWith('/api/v1') ? clean : '$clean/api/v1';
    }
    if (host.startsWith('http://') || host.startsWith('https://')) {
      final clean = host.replaceAll(RegExp(r'/+$'), '');
      return clean.endsWith('/api/v1') ? clean : '$clean/api/v1';
    }
    if (port == 443) {
      return 'https://$host/api/v1';
    }
    if (port == 80) {
      return 'http://$host/api/v1';
    }
    return 'http://$host:$port/api/v1';
  }

  static String get defaultBaseUrl => _buildBaseUrl(serverHostIp, serverPort);

  static String apiBaseUrl = defaultBaseUrl;

  static String get serverAddress {
    if (productionServerUrl.trim().isNotEmpty) {
      final uri = Uri.tryParse(productionServerUrl.trim());
      if (uri != null && uri.host.isNotEmpty) return uri.host;
    }
    return '$serverHostIp:$serverPort';
  }

  static String get serverOrigin {
    if (productionServerUrl.trim().isNotEmpty) {
      final clean = productionServerUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final idx = clean.indexOf('/api/v1');
      return idx != -1 ? clean.substring(0, idx) : clean;
    }
    if (serverHostIp.startsWith('http://') || serverHostIp.startsWith('https://')) {
      final clean = serverHostIp.replaceAll(RegExp(r'/+$'), '');
      final idx = clean.indexOf('/api/v1');
      return idx != -1 ? clean.substring(0, idx) : clean;
    }
    if (serverPort == 443) return 'https://$serverHostIp';
    if (serverPort == 80) return 'http://$serverHostIp';
    return 'http://$serverHostIp:$serverPort';
  }

  static Future<void> initializeServerConfig(SecureStorageService storage) async {
    try {
      final savedIp = await storage.getServerIp();
      final savedPort = await storage.getServerPort();
      if (savedIp != null && savedIp.trim().isNotEmpty) {
        serverHostIp = savedIp.trim();
      }
      if (savedPort != null && savedPort > 0) {
        serverPort = savedPort;
      }
      apiBaseUrl = _buildBaseUrl(serverHostIp, serverPort);
    } catch (_) {}
  }

  static Future<void> updateServerConfig(SecureStorageService storage, String ip, int port) async {
    serverHostIp = ip.trim();
    serverPort = port;
    apiBaseUrl = _buildBaseUrl(serverHostIp, serverPort);
    await storage.saveServerConfig(serverHostIp, serverPort);
  }

  static const String appName = 'MarLink';
  static const String appTagline = 'Connect. Locate. Stay Together.';
  static const String appVersion = '1.0.0';

  // Tile Server for OpenStreetMap
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackageName = 'com.marlink.app';
}
