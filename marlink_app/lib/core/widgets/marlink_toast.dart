import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum MarLinkToastType { success, error, info, warning, loading }

class MarLinkToast {
  MarLinkToast._();

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: MarLinkToastType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: MarLinkToastType.error,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: MarLinkToastType.info,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      type: MarLinkToastType.warning,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    MarLinkToastType type = MarLinkToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    Color accentColor;
    Color iconBgColor;
    IconData iconData;

    switch (type) {
      case MarLinkToastType.success:
        accentColor = const Color(0xFF10B981);
        iconBgColor = const Color(0xFF10B981).withValues(alpha: 0.18);
        iconData = Icons.check_circle_rounded;
        break;
      case MarLinkToastType.error:
        accentColor = const Color(0xFFEF4444);
        iconBgColor = const Color(0xFFEF4444).withValues(alpha: 0.18);
        iconData = Icons.error_rounded;
        break;
      case MarLinkToastType.warning:
        accentColor = const Color(0xFFF59E0B);
        iconBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.18);
        iconData = Icons.warning_amber_rounded;
        break;
      case MarLinkToastType.loading:
        accentColor = AppColors.brandSky;
        iconBgColor = AppColors.brandSky.withValues(alpha: 0.18);
        iconData = Icons.hourglass_top_rounded;
        break;
      case MarLinkToastType.info:
        accentColor = AppColors.brandSky;
        iconBgColor = AppColors.brandSky.withValues(alpha: 0.18);
        iconData = Icons.info_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(
          bottom: 24,
          left: 16,
          right: 16,
        ),
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1E38).withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.18),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBgColor,
                ),
                child: Center(
                  child: type == MarLinkToastType.loading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accentColor,
                          ),
                        )
                      : Icon(iconData, color: accentColor, size: 19),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
