import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback? onConfigSaved;

  const ServerConfigDialog({super.key, this.onConfigSaved});

  static Future<void> show(BuildContext context, {VoidCallback? onConfigSaved}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => ServerConfigDialog(onConfigSaved: onConfigSaved),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _ipController;
  late final TextEditingController _portController;
  final SecureStorageService _storage = SecureStorageService();

  bool _isTesting = false;
  String? _testResult;
  bool? _isTestSuccess;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: AppConfig.serverHostIp);
    _portController = TextEditingController(text: AppConfig.serverPort.toString());
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8000;

    if (ip.isEmpty) {
      setState(() {
        _isTestSuccess = false;
        _testResult = 'Please enter a valid IP address.';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
      _isTestSuccess = null;
    });

    final success = await ApiClient.testServerConnection(ip, port);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _isTestSuccess = success;
        _testResult = success
            ? 'Connected! Server is online and reachable.'
            : 'Cannot reach server at $ip:$port.\nCheck that your PC and phone are on the same Wi-Fi.';
      });
    }
  }

  Future<void> _saveConfig() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8000;

    if (ip.isEmpty) return;

    await AppConfig.updateServerConfig(_storage, ip, port);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onConfigSaved?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.statusOnline, size: 18),
              const SizedBox(width: 8),
              Text('Server set to ${AppConfig.serverAddress}'),
            ],
          ),
          backgroundColor: AppColors.darkSurface,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _resetDefault() {
    setState(() {
      _ipController.text = AppConfig.defaultServerHostIp;
      _portController.text = AppConfig.defaultServerPort.toString();
      _testResult = null;
      _isTestSuccess = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brandSky.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dns_rounded, color: AppColors.brandSky, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Server Connection',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Wi-Fi & API Endpoint Config',
                        style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Explanatory note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.brandSky),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you switch Wi-Fi, update the IP address to match your computer\'s current IPv4 address.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // IP Address field
            const Text(
              'Computer / Host IP Address',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _ipController,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'e.g. 192.168.4.43',
                prefixIcon: const Icon(Icons.wifi, size: 18),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.brandSky, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Port field
            const Text(
              'Port',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '8000',
                prefixIcon: const Icon(Icons.numbers, size: 18),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.brandSky, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Test connection result banner
            if (_testResult != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isTestSuccess == true
                      ? AppColors.statusOnline.withValues(alpha: 0.12)
                      : AppColors.alertEmergency.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isTestSuccess == true
                        ? AppColors.statusOnline.withValues(alpha: 0.4)
                        : AppColors.alertEmergency.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isTestSuccess == true ? Icons.check_circle : Icons.error_outline,
                      size: 16,
                      color: _isTestSuccess == true ? AppColors.statusOnline : AppColors.alertEmergency,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _isTestSuccess == true ? AppColors.statusOnline : AppColors.alertEmergency,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Actions row: Test button and Reset button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.electrical_services_rounded, size: 16),
                    label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _resetDefault,
                  child: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            const SizedBox(height: 14),

            // Save and Cancel buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandSky,
                    foregroundColor: AppColors.brandNavy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
