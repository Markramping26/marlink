import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/call_repository.dart';
import '../domain/models/call_model.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  return CallRepository();
});

class CallState {
  final CallModel? activeCall;
  final CallModel? incomingCall;
  final Duration callDuration;
  final bool isMuted;
  final bool isCameraOff;
  final bool isFrontCamera;
  final bool isSpeakerOn;
  final bool isLoading;
  final String? errorMessage;

  const CallState({
    this.activeCall,
    this.incomingCall,
    this.callDuration = Duration.zero,
    this.isMuted = false,
    this.isCameraOff = false,
    this.isFrontCamera = true,
    this.isSpeakerOn = false,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isInCall => activeCall != null && !activeCall!.isEnded;
  bool get hasIncomingCall => incomingCall != null && !incomingCall!.isEnded;

  CallState copyWith({
    CallModel? activeCall,
    bool clearActiveCall = false,
    CallModel? incomingCall,
    bool clearIncomingCall = false,
    Duration? callDuration,
    bool? isMuted,
    bool? isCameraOff,
    bool? isFrontCamera,
    bool? isSpeakerOn,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CallState(
      activeCall: clearActiveCall ? null : (activeCall ?? this.activeCall),
      incomingCall: clearIncomingCall ? null : (incomingCall ?? this.incomingCall),
      callDuration: callDuration ?? this.callDuration,
      isMuted: isMuted ?? this.isMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final callNotifierProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  final repo = ref.watch(callRepositoryProvider);
  return CallNotifier(repo, ref);
});

class CallNotifier extends StateNotifier<CallState> {
  final CallRepository _repository;
  final Ref _ref;
  Timer? _durationTimer;
  Timer? _pollTimer;

  CallNotifier(this._repository, this._ref) : super(const CallState());

  /// Initiate a Voice or Video Call in a room (or direct to a specific member)
  Future<CallModel?> startCall(int roomId, {bool isVideo = false, int? targetUserId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final call = await _repository.initiateCall(
        roomId,
        callType: isVideo ? 'video' : 'voice',
        targetUserId: targetUserId,
      );
      state = state.copyWith(
        isLoading: false,
        activeCall: call,
        callDuration: Duration.zero,
        isMuted: false,
        isCameraOff: !isVideo, // Camera is OFF by default for voice calls!
        isFrontCamera: true,
        isSpeakerOn: isVideo, // Auto-speaker for video call
      );

      // Do NOT start duration timer immediately. Wait until answered.
      _startCallPolling(call.id);
      return call;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to initiate call.');
      return null;
    }
  }

  /// Detected an incoming call for the user
  void setIncomingCall(CallModel call) {
    if (state.activeCall?.id == call.id) return;
    if (state.incomingCall?.id == call.id) return;

    state = state.copyWith(incomingCall: call);
    NotificationService.instance.startRingtone();
    NotificationService.instance.showIncomingCallNotification(
      callerName: call.initiatorName,
      roomName: call.roomName,
      isVideo: call.isVideo,
      callId: call.id,
    );
  }

  /// Answer incoming call
  Future<CallModel?> answerIncomingCall() async {
    final incoming = state.incomingCall;
    if (incoming == null) return null;

    NotificationService.instance.stopRingtone();
    NotificationService.instance.cancelNotification(8888);

    state = state.copyWith(
      isLoading: true,
      clearIncomingCall: true,
      errorMessage: null,
    );

    try {
      final updated = await _repository.joinCall(incoming.id);
      final finalCall = updated ?? incoming;

      state = state.copyWith(
        isLoading: false,
        activeCall: finalCall,
        callDuration: Duration.zero,
        isMuted: false,
        isCameraOff: false,
        isFrontCamera: true,
        isSpeakerOn: finalCall.isVideo,
      );

      _startDurationTimer();
      _startCallPolling(finalCall.id);
      return finalCall;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to join call.');
      return null;
    }
  }

  /// Decline incoming call
  Future<void> declineIncomingCall() async {
    final incoming = state.incomingCall;
    NotificationService.instance.stopRingtone();
    NotificationService.instance.cancelNotification(8888);

    if (incoming != null) {
      await _repository.declineCall(incoming.id);
    }

    state = state.copyWith(clearIncomingCall: true);
  }

  /// Terminate active call
  Future<void> endCall() async {
    final active = state.activeCall;
    _stopTimers();
    NotificationService.instance.stopRingtone();
    NotificationService.instance.cancelNotification(8888);

    if (active != null) {
      await _repository.endCall(active.id);
    }

    state = state.copyWith(
      clearActiveCall: true,
      callDuration: Duration.zero,
      isMuted: false,
      isCameraOff: false,
    );
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void toggleCamera() {
    state = state.copyWith(isCameraOff: !state.isCameraOff);
  }

  void toggleSpeaker() {
    state = state.copyWith(isSpeakerOn: !state.isSpeakerOn);
  }

  void flipCamera() {
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(callDuration: state.callDuration + const Duration(seconds: 1));
    });
  }

  void _startCallPolling(int callId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final details = await _repository.getCallDetails(callId);
      if (details != null) {
        if (details.isEnded) {
          endCall();
        } else {
          state = state.copyWith(activeCall: details);
          final isAnswered = details.isActive ||
              details.participants.any((p) => p.userId != details.initiatorId && p.isJoined);
          if (isAnswered && _durationTimer == null) {
            _startDurationTimer();
          }
        }
      }
    });
  }

  void _stopTimers() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Background sync check for active/incoming calls
  Future<void> syncActiveCall() async {
    final currentUserId = _ref.read(authNotifierProvider).user?.id;
    if (currentUserId == null) return;

    final active = await _repository.getActiveCall();
    if (active == null || active.isEnded) {
      if (state.incomingCall != null) {
        NotificationService.instance.stopRingtone();
        NotificationService.instance.cancelNotification(8888);
        state = state.copyWith(clearIncomingCall: true);
      }
      return;
    }

    // Check if this is an incoming call to me
    final isInitiator = active.initiatorId == currentUserId;
    if (!isInitiator) {
      // Find my participant status
      final myPart = active.participants.where((p) => p.userId == currentUserId).firstOrNull;
      if (myPart != null && myPart.isRinging) {
        setIncomingCall(active);
      } else if (myPart != null && myPart.isDeclined && state.incomingCall != null) {
        state = state.copyWith(clearIncomingCall: true);
      }
    }
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
