import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:marlink_app/core/theme/app_colors.dart';
import 'package:marlink_app/core/widgets/marlink_avatar.dart';
import '../../../alerts/domain/models/alert_model.dart';
import '../../domain/models/member_location_model.dart';

class MemberMarkerWidget extends StatefulWidget {
  final MemberLocationModel member;
  final bool isSelected;
  final AlertModel? alert;
  final VoidCallback onTap;

  const MemberMarkerWidget({
    super.key,
    required this.member,
    this.isSelected = false,
    this.alert,
    required this.onTap,
  });

  bool get hasAlert => alert != null && alert!.isActive;

  @override
  State<MemberMarkerWidget> createState() => _MemberMarkerWidgetState();
}

class _MemberMarkerWidgetState extends State<MemberMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.alert != null) {
      _rippleController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MemberMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.alert != null && !oldWidget.hasAlert) {
      _rippleController.repeat();
    } else if (widget.alert == null && oldWidget.hasAlert) {
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  bool get hasAlert => widget.alert != null && widget.alert!.isActive;

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final isMoving = member.isMoving && member.speed != null && member.speed! > 3.0;
    final alert = widget.alert;
    final isAlertActive = hasAlert;

    // Pin theme colors based on state
    final Color pinColor = isAlertActive
        ? const Color(0xFFE53935) // Emergency vibrant red
        : (widget.isSelected
            ? AppColors.brandSky
            : (isMoving ? AppColors.statusOnline : AppColors.brandNavy));

    final Color borderColor = isAlertActive
        ? Colors.white
        : (widget.isSelected
            ? Colors.white
            : (isMoving ? AppColors.statusOnline : AppColors.brandSky));

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRect(
        child: SizedBox(
          width: 92,
          height: 92,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Animated Radar Ripple Effect if alert active
                  if (isAlertActive)
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        final val = _rippleController.value;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer Wave
                            Transform.scale(
                              scale: 1.0 + (val * 0.9),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE53935).withValues(
                                      alpha: math.max(0.0, 0.7 * (1.0 - val)),
                                    ),
                                    width: 2.2,
                                  ),
                                ),
                              ),
                            ),
                            // Inner Wave
                            Transform.scale(
                              scale: 1.0 + (val * 0.45),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFE53935).withValues(
                                    alpha: math.max(0.0, 0.25 * (1.0 - val)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  // Pin & Label Column
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Location Pin (Teardrop shape with avatar)
                      CustomPaint(
                        painter: _LocationPinPainter(
                          pinColor: pinColor,
                          borderColor: borderColor,
                          isSelected: widget.isSelected,
                          isAlert: isAlertActive,
                        ),
                        child: Container(
                          width: 44,
                          height: 52,
                          padding: const EdgeInsets.only(top: 3.0, left: 3.0, right: 3.0),
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: MarLinkAvatar(
                                imageUrl: member.avatarUrl,
                                name: member.displayName,
                                radius: 19,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      // 2. Member Name & Status Pill
                      Container(
                        constraints: const BoxConstraints(maxWidth: 88),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAlertActive
                              ? const Color(0xFFDC2626)
                              : AppColors.brandNavy.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAlertActive
                                ? Colors.white
                                : (widget.isSelected
                                    ? AppColors.brandSky
                                    : Colors.white.withValues(alpha: 0.18)),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isAlertActive
                                  ? Colors.red.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.25),
                              blurRadius: isAlertActive ? 6 : 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isAlertActive) ...[
                              Text(
                                alert?.isSos == true
                                    ? '🚨 SOS'
                                    : '🚨 ${(alert?.alertType ?? "ALERT").toUpperCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ] else ...[
                              Flexible(
                                child: Text(
                                  member.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: widget.isSelected ? AppColors.brandSky : Colors.white,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isMoving) ...[
                                const SizedBox(width: 3),
                                Text(
                                  '${member.speed!.round()}k',
                                  style: const TextStyle(
                                    color: AppColors.statusOnline,
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationPinPainter extends CustomPainter {
  final Color pinColor;
  final Color borderColor;
  final bool isSelected;
  final bool isAlert;

  const _LocationPinPainter({
    required this.pinColor,
    required this.borderColor,
    this.isSelected = false,
    this.isAlert = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2;

    final path = Path();
    // Arc across the top of the pin
    path.arcTo(
      Rect.fromCircle(center: Offset(r, r), radius: r),
      math.pi * 0.75,
      math.pi * 1.5,
      false,
    );
    // Draw straight line down to pointer tip
    path.lineTo(r, h);
    path.close();

    // Drop shadow
    final shadowPaint = Paint()
      ..color = (isAlert ? Colors.redAccent : Colors.black).withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isAlert ? 6 : 4);
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);

    // If selected or alert, draw glowing outer halo
    if (isSelected || isAlert) {
      final glowPaint = Paint()
        ..color = (isAlert ? const Color(0xFFEF4444) : AppColors.brandSky)
            .withValues(alpha: isAlert ? 0.6 : 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isAlert ? 5.0 : 4.0;
      canvas.drawPath(path, glowPaint);
    }

    // Pin Fill
    final fillPaint = Paint()
      ..color = pinColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Pin Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAlert ? 2.5 : 2.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _LocationPinPainter oldDelegate) {
    return oldDelegate.pinColor != pinColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isAlert != isAlert;
  }
}
