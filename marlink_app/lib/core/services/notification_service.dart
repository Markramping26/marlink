import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const MethodChannel _channel = MethodChannel('com.marlink.app/notifications');

  /// Request runtime notification permissions on Android 13+
  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (e) {
      debugPrint('NotificationService: requestPermission error: $e');
    }
  }

  /// Show a system heads-up notification in the Android status bar
  Future<void> showNotification({
    required String title,
    required String body,
    bool isAlert = false,
    bool isCall = false,
    int? id,
  }) async {
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
        'isAlert': isAlert,
        'isCall': isCall,
        if (id != null) 'id': id,
      });
    } catch (e) {
      debugPrint('NotificationService: showNotification error: $e');
    }
  }

  /// High-priority Incoming Call system notification with emerald styling & ringing vibration
  Future<void> showIncomingCallNotification({
    required String callerName,
    required String roomName,
    required bool isVideo,
    required int callId,
  }) async {
    final typeStr = isVideo ? 'Video Call' : 'Voice Call';
    final icon = isVideo ? '📹' : '📞';
    await showNotification(
      title: '$icon Incoming $typeStr: $callerName',
      body: '$callerName is calling you in "$roomName"... Tap to answer.',
      isAlert: false,
      isCall: true,
      id: 8888,
    );
  }

  /// Start playing continuous incoming call ringtone
  Future<void> startRingtone() async {
    try {
      await _channel.invokeMethod('startRingtone');
    } catch (e) {
      debugPrint('NotificationService: startRingtone error: $e');
    }
  }

  /// Stop playing incoming call ringtone
  Future<void> stopRingtone() async {
    try {
      await _channel.invokeMethod('stopRingtone');
    } catch (e) {
      debugPrint('NotificationService: stopRingtone error: $e');
    }
  }

  /// Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    try {
      await _channel.invokeMethod('cancelNotification', {'id': id});
    } catch (e) {
      debugPrint('NotificationService: cancelNotification error: $e');
    }
  }

  /// High-priority SOS Alert notification with distinct sound and vibration
  Future<void> showSosAlert({
    required String senderName,
    required String roomName,
  }) async {
    await showNotification(
      title: '🚨 EMERGENCY SOS: $senderName',
      body: '$senderName triggered an emergency alert in room "$roomName"!',
      isAlert: true,
      id: 9999,
    );
  }

  /// Notification for incoming chat message (heads-up banner with sound chime)
  Future<void> showChatMessage({
    required String senderName,
    required String message,
    required String roomName,
    bool playSound = true,
  }) async {
    await showNotification(
      title: '💬 $senderName • $roomName',
      body: message,
      isAlert: false,
    );
    if (playSound) {
      await playChime();
    }
  }

  /// Notification for member proximity / arrival
  Future<void> showProximityAlert({
    required String memberName,
    required String distanceText,
  }) async {
    await showNotification(
      title: '📍 Member Proximity Alert',
      body: '$memberName is nearby ($distanceText away)',
      isAlert: false,
    );
  }

  /// Play audio cue chime
  Future<void> playChime() async {
    try {
      await _channel.invokeMethod('playChime');
    } catch (_) {}
  }
}
