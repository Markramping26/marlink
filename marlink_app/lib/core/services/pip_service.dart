import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PipService {
  PipService._();
  static final PipService instance = PipService._();

  static const MethodChannel _channel = MethodChannel('com.marlink.app/pip');

  final ValueNotifier<bool> isPipMode = ValueNotifier<bool>(false);

  void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPipModeChanged') {
        final bool inPip = call.arguments as bool? ?? false;
        isPipMode.value = inPip;
      }
    });
  }

  /// Request the native Android host to enter Picture-in-Picture mode
  Future<bool> enterPip() async {
    try {
      final bool? result = await _channel.invokeMethod<bool>('enterPip');
      return result ?? false;
    } catch (e) {
      debugPrint('PipService: Failed to enter PiP: $e');
      return false;
    }
  }

  /// Enable or disable automatic PiP entry when user swipes home
  Future<void> setAutoPip(bool enabled) async {
    try {
      await _channel.invokeMethod('setAutoPip', {'enabled': enabled});
    } catch (e) {
      debugPrint('PipService: Failed to set auto PiP: $e');
    }
  }

  /// Check whether PiP is supported on this device
  Future<bool> isPipSupported() async {
    try {
      final bool? supported = await _channel.invokeMethod<bool>('isPipSupported');
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }
}
