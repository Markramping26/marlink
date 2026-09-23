import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../../../core/services/pip_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/marlink_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/models/call_model.dart';
import '../providers/call_provider.dart';

class CallScreen extends ConsumerStatefulWidget {
  final CallModel call;

  const CallScreen({super.key, required this.call});

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  List<CameraDescription> _availableCameras = [];
  CameraController? _cameraController;
  bool _isCameraInitializing = false;
  bool _isSelfViewFullscreen = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    if (widget.call.isVideo) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    if (!mounted || _isCameraInitializing) return;
    setState(() => _isCameraInitializing = true);
    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      if (_availableCameras.isNotEmpty) {
        final frontCam = _availableCameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _availableCameras.first,
        );
        await _setupCameraController(frontCam);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    } finally {
      if (mounted) setState(() => _isCameraInitializing = false);
    }
  }

  Future<void> _setupCameraController(CameraDescription description) async {
    final oldController = _cameraController;
    _cameraController = null;
    if (mounted) setState(() {});
    await oldController?.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
        });
      } else {
        await controller.dispose();
      }
    } catch (e) {
      debugPrint('Error starting camera controller: $e');
      await controller.dispose();
    }
  }

  Future<void> _flipCamera() async {
    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      if (_availableCameras.length < 2) return;

      final currentLens = _cameraController?.description.lensDirection ?? CameraLensDirection.front;
      final targetLens = currentLens == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;

      final nextCamera = _availableCameras.firstWhere(
        (c) => c.lensDirection == targetLens,
        orElse: () => _availableCameras.first,
      );

      await _setupCameraController(nextCamera);
      ref.read(callNotifierProvider.notifier).flipCamera();
    } catch (e) {
      debugPrint('Error flipping camera: $e');
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Resolve who should be displayed in the center:
  /// - Group call: Group Name & Group Icon
  /// - Direct 1-on-1 call: Recipient / other member's name and avatar
  /// - Incoming call: Caller's name and avatar
  ({String title, String? avatarUrl, bool isGroup}) _getDisplayInfo(
      CallModel activeCall, int? currentUserId) {
    final isInitiator = currentUserId != null && currentUserId == activeCall.initiatorId;
    if (isInitiator) {
      if (activeCall.isDirectCall && activeCall.directRecipient != null) {
        return (
          title: activeCall.directRecipient!.name,
          avatarUrl: activeCall.directRecipient!.avatarUrl,
          isGroup: false,
        );
      } else {
        return (
          title: activeCall.roomName,
          avatarUrl: null,
          isGroup: true,
        );
      }
    } else {
      return (
        title: activeCall.initiatorName,
        avatarUrl: activeCall.initiatorAvatar,
        isGroup: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callNotifierProvider);
    final activeCall = callState.activeCall ?? widget.call;
    final authUser = ref.watch(authNotifierProvider).user;
    final currentUserId = authUser?.id;

    final displayInfo = _getDisplayInfo(activeCall, currentUserId);
    final hasCameraActive = _cameraController != null &&
        _cameraController!.value.isInitialized &&
        !callState.isCameraOff;
    final isVideo = activeCall.isVideo || hasCameraActive;
    final isConnected = activeCall.isActive || callState.callDuration.inSeconds > 0;

    // Listen for call ended to pop screen automatically
    ref.listen<CallState>(callNotifierProvider, (prev, next) {
      if (prev?.activeCall != null && next.activeCall == null) {
        if (mounted) Navigator.of(context).maybePop();
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;

    return ValueListenableBuilder<bool>(
      valueListenable: PipService.instance.isPipMode,
      builder: (context, isPip, _) {
        if (isPip || screenWidth < 280) {
          return _buildPipCallView(callState, activeCall, displayInfo, isConnected, hasCameraActive);
        }

        return Scaffold(
          backgroundColor: const Color(0xFF070D1E),
          body: Stack(
            children: [
              // 1. Ambient Background Glows
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandSky.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: -100,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brandBlue.withValues(alpha: 0.15),
                  ),
                ),
              ),

              // 2. Video View or Voice Call Centerpiece
              if (isVideo)
                _buildVideoBody(callState, activeCall, displayInfo)
              else
                _buildVoiceBody(callState, activeCall, displayInfo, isConnected),

              // 3. Top Header Bar (With Safe Flex Constraints)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        // Minimize / Back button
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.white, size: 26),
                            onPressed: () => Navigator.of(context).pop(),
                            tooltip: 'Minimize Call',
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Title & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayInfo.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isConnected
                                          ? AppColors.statusOnline
                                          : Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      isConnected
                                          ? _formatDuration(callState.callDuration)
                                          : 'Ringing...',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isConnected
                                            ? AppColors.statusOnline
                                            : Colors.amber,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Security encryption badge (Only if enough room)
                        if (screenWidth > 330)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline_rounded,
                                    size: 11, color: AppColors.brandSky),
                                SizedBox(width: 3),
                                Text(
                                  'Encrypted',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.brandSky,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Bottom Call Controls Dock (Auto-scaled, no overflow)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: _buildControlDock(callState, isVideo, activeCall),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Compact, zero-overflow view for Picture-in-Picture / narrow floating windows
  Widget _buildPipCallView(
    CallState callState,
    CallModel activeCall,
    ({String title, String? avatarUrl, bool isGroup}) displayInfo,
    bool isConnected,
    bool hasCameraActive,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF091226),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background video or avatar
          if (hasCameraActive && _cameraController != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _cameraController!.value.previewSize?.height ?? 120,
                height: _cameraController!.value.previewSize?.width ?? 160,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            Center(
              child: displayInfo.isGroup
                  ? Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                    )
                  : MarLinkAvatar(
                      imageUrl: displayInfo.avatarUrl,
                      name: displayInfo.title,
                      radius: 28,
                    ),
            ),

          // Top status pill
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? AppColors.statusOnline : Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      displayInfo.title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    isConnected ? _formatDuration(callState.callDuration) : 'Ring',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isConnected ? AppColors.statusOnline : Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom end call button
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () async {
                  await ref.read(callNotifierProvider.notifier).endCall();
                  if (mounted) Navigator.of(context).maybePop();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFEF4444),
                  ),
                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBody(
    CallState callState,
    CallModel activeCall,
    ({String title, String? avatarUrl, bool isGroup}) displayInfo,
    bool isConnected,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 70),

            // Animated Pulse Soundwaves around Center Avatar
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Wave Ring
                    Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.35),
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.brandSky.withValues(
                              alpha: math.max(0.0, 0.4 * (1.0 - _pulseController.value)),
                            ),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Middle Wave Ring
                    Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.18),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.brandSky.withValues(
                            alpha: math.max(0.0, 0.15 * (1.0 - _pulseController.value)),
                          ),
                        ),
                      ),
                    ),
                    // Main Avatar or Group Icon
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brandSky.withValues(alpha: 0.35),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: displayInfo.isGroup
                          ? Container(
                              width: 106,
                              height: 106,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0F1B35),
                              ),
                              child: const Center(
                                child: Icon(Icons.groups_rounded,
                                    color: Colors.white, size: 52),
                              ),
                            )
                          : MarLinkAvatar(
                              imageUrl: displayInfo.avatarUrl,
                              name: displayInfo.title,
                              radius: 53,
                            ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Call recipient / Room Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                displayInfo.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isConnected
                  ? (activeCall.isVideo ? 'Video Connected' : 'Voice Connected')
                  : (displayInfo.isGroup ? 'Calling group members...' : 'Calling ${displayInfo.title}...'),
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.darkTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            // Large Timer Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Text(
                isConnected ? _formatDuration(callState.callDuration) : 'Ringing...',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  fontFamily: isConnected ? 'monospace' : null,
                  color: isConnected ? Colors.white : Colors.amber,
                  letterSpacing: isConnected ? 1.2 : 0.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Participants Chips
            if (activeCall.participants.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: activeCall.participants.map((p) {
                    final isJoined = p.isJoined;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isJoined
                            ? AppColors.statusOnline.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isJoined
                              ? AppColors.statusOnline.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isJoined ? AppColors.statusOnline : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.name,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isJoined ? Colors.white : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 120), // Bottom dock breathing space
          ],
        ),
      ),
    );
  }

  Widget _buildVideoBody(
    CallState callState,
    CallModel activeCall,
    ({String title, String? avatarUrl, bool isGroup}) displayInfo,
  ) {
    final isConnected = activeCall.isActive || callState.callDuration.inSeconds > 0;
    final hasLiveCamera = _cameraController != null &&
        _cameraController!.value.isInitialized &&
        !callState.isCameraOff;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main Canvas: either user's full camera preview OR remote participant view
        GestureDetector(
          onTap: () {
            if (hasLiveCamera) {
              setState(() => _isSelfViewFullscreen = !_isSelfViewFullscreen);
            }
          },
          child: Container(
            color: const Color(0xFF0A1224),
            child: _isSelfViewFullscreen
                ? (hasLiveCamera
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _cameraController!.value.previewSize?.height ?? 720,
                          height: _cameraController!.value.previewSize?.width ?? 1280,
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    : _buildCameraOffPlaceholder(displayInfo))
                : _buildRemoteParticipantCanvas(activeCall, displayInfo, isConnected),
          ),
        ),

        // Floating Picture-in-Picture Tile (Top Right)
        Positioned(
          top: 80,
          right: 14,
          child: GestureDetector(
            onTap: () {
              setState(() => _isSelfViewFullscreen = !_isSelfViewFullscreen);
            },
            child: Container(
              width: 104,
              height: 142,
              decoration: BoxDecoration(
                color: const Color(0xFF162544),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.brandSky.withValues(alpha: 0.6),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_isSelfViewFullscreen)
                      // Small remote participant preview
                      Container(
                        color: const Color(0xFF0F1A30),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              displayInfo.isGroup
                                  ? const Icon(Icons.groups_rounded,
                                      color: Colors.white, size: 28)
                                  : MarLinkAvatar(
                                      imageUrl: displayInfo.avatarUrl,
                                      name: displayInfo.title,
                                      radius: 22,
                                    ),
                              const SizedBox(height: 5),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  displayInfo.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Small self camera preview
                      if (hasLiveCamera)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize?.height ?? 104,
                            height: _cameraController!.value.previewSize?.width ?? 142,
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                      else if (_isCameraInitializing)
                        Container(
                          color: const Color(0xFF0F1A30),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.brandSky,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: const Color(0xFF0F1A30),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  callState.isCameraOff
                                      ? Icons.videocam_off_rounded
                                      : Icons.person_rounded,
                                  color: Colors.white38,
                                  size: 26,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  callState.isCameraOff ? 'Camera Off' : 'No Video',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white60,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                    // Label tag
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isSelfViewFullscreen ? displayInfo.title : 'You',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Swap view icon
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraOffPlaceholder(
      ({String title, String? avatarUrl, bool isGroup}) displayInfo) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brandSky, width: 2),
            ),
            child: displayInfo.isGroup
                ? const Icon(Icons.groups_rounded, color: Colors.white, size: 54)
                : MarLinkAvatar(
                    imageUrl: displayInfo.avatarUrl,
                    name: displayInfo.title,
                    radius: 52,
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            displayInfo.title,
            style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Camera is turned off',
            style: TextStyle(fontSize: 12.5, color: AppColors.darkTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteParticipantCanvas(
    CallModel activeCall,
    ({String title, String? avatarUrl, bool isGroup}) displayInfo,
    bool isConnected,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                Color(0xFF1E3258),
                Color(0xFF091226),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: displayInfo.isGroup
                      ? Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0F1B35),
                          ),
                          child: const Center(
                            child: Icon(Icons.groups_rounded,
                                color: Colors.white, size: 44),
                          ),
                        )
                      : MarLinkAvatar(
                          imageUrl: displayInfo.avatarUrl,
                          name: displayInfo.title,
                          radius: 46,
                        ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayInfo.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppColors.statusOnline.withValues(alpha: 0.15)
                        : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isConnected ? Icons.videocam : Icons.ring_volume,
                        size: 13,
                        color: isConnected ? AppColors.statusOnline : Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isConnected ? 'Connected' : 'Ringing...',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isConnected ? AppColors.statusOnline : Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlDock(CallState callState, bool isVideo, CallModel activeCall) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B35).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: const Color(0xFF1E3258),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. Mute / Unmute Button
            _buildDockButton(
              icon: callState.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              isActive: !callState.isMuted,
              activeColor: Colors.white,
              inactiveColor: Colors.redAccent,
              onTap: () {
                ref.read(callNotifierProvider.notifier).toggleMute();
              },
              tooltip: callState.isMuted ? 'Unmute' : 'Mute',
            ),
            const SizedBox(width: 10),

            // 2. Camera Toggle (Available in BOTH Voice and Video Calls!)
            _buildDockButton(
              icon: callState.isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
              isActive: !callState.isCameraOff,
              activeColor: Colors.white,
              inactiveColor: Colors.redAccent,
              onTap: () async {
                final wasCameraOff = callState.isCameraOff;
                ref.read(callNotifierProvider.notifier).toggleCamera();
                if (wasCameraOff) {
                  // User is turning camera ON! Initialize if needed
                  if (_cameraController == null || !_cameraController!.value.isInitialized) {
                    await _initCamera();
                  }
                }
              },
              tooltip: callState.isCameraOff ? 'Turn Camera On' : 'Turn Camera Off',
            ),
            const SizedBox(width: 10),

            // 3. Flip Camera Button (Always accessible when camera is initialized)
            if (_cameraController != null && _cameraController!.value.isInitialized) ...[
              _buildDockButton(
                icon: Icons.flip_camera_ios_rounded,
                isActive: true,
                activeColor: Colors.white,
                onTap: () {
                  _flipCamera();
                },
                tooltip: 'Flip Camera',
              ),
              const SizedBox(width: 10),
            ],

            // 4. Speakerphone Toggle
            _buildDockButton(
              icon: callState.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
              isActive: callState.isSpeakerOn,
              activeColor: AppColors.brandSky,
              inactiveColor: Colors.white60,
              onTap: () {
                ref.read(callNotifierProvider.notifier).toggleSpeaker();
              },
              tooltip: callState.isSpeakerOn ? 'Speaker On' : 'Speaker Off',
            ),
            const SizedBox(width: 12),

            // 5. End Call Button (Red Circle)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await ref.read(callNotifierProvider.notifier).endCall();
                  if (mounted) Navigator.of(context).maybePop();
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required bool isActive,
    Color activeColor = Colors.white,
    Color inactiveColor = Colors.white54,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.redAccent.withValues(alpha: 0.15),
              border: Border.all(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.redAccent.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
