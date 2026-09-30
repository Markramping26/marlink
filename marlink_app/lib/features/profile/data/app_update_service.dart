import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';

class AppUpdateInfo {
  final String latestVersion;
  final int buildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final String fallbackUrl;
  final bool isMandatory;
  final String releaseDate;

  AppUpdateInfo({
    required this.latestVersion,
    required this.buildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.fallbackUrl,
    this.isMandatory = false,
    required this.releaseDate,
  });

  bool get isUpdateAvailable => buildNumber > AppConfig.appBuildNumber;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      buildNumber: json['build_number'] is int
          ? json['build_number']
          : int.tryParse(json['build_number']?.toString() ?? '1') ?? 1,
      releaseNotes: json['release_notes']?.toString() ??
          'General performance improvements and UI enhancements.',
      downloadUrl: json['download_url']?.toString() ??
          'https://github.com/Markramping26/marlink/raw/main/marlink_api/MarLink.apk',
      fallbackUrl: json['fallback_url']?.toString() ??
          'https://marlink-api.onrender.com/download',
      isMandatory: json['is_mandatory'] == true,
      releaseDate: json['release_date']?.toString() ?? '',
    );
  }
}

class AppUpdateService {
  final ApiClient _apiClient;

  AppUpdateService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<AppUpdateInfo?> checkUpdate() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.appVersion);
      if (response.success && response.data != null) {
        return AppUpdateInfo.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {}

    // Fallback: Always return the latest release from the official repository CDN
    return AppUpdateInfo(
      latestVersion: '1.0.1',
      buildNumber: 2,
      releaseNotes: '• Fixed Voice Call and Video Call buttons\n• Fixed Leave Group button\n• Added Room Admin Kick member feature\n• Performance and UI improvements',
      downloadUrl: 'https://github.com/Markramping26/marlink/raw/main/marlink_api/MarLink.apk',
      fallbackUrl: 'https://marlink-api.onrender.com/download',
      isMandatory: false,
      releaseDate: '2026-09-30',
    );
  }

  static Future<bool> launchDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});
