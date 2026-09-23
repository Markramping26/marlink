import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haversine_calculator.dart';
import '../../../../core/widgets/marlink_avatar.dart';
import '../../domain/models/message_model.dart';
import 'location_card_bubble.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onOpenLocation;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onOpenLocation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isCallLog) {
      return _buildCallLogBubble(context, isDark);
    }

    if (message.isLocation) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: LocationCardBubble(
          message: message,
          isMe: isMe,
          onOpenMap: onOpenLocation,
        ),
      );
    }

    final timeStr = HaversineCalculator.formatRelativeTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            MarLinkAvatar(
              imageUrl: message.senderAvatar,
              name: message.senderName,
              radius: 15,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.brandSky : AppColors.brandBlue,
                      ),
                    ),
                  ),

                // Message Body Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppColors.primaryGradient : null,
                    color: isMe
                        ? null
                        : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 1,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Attachment
                      if (message.isImage) ...[
                        Builder(
                          builder: (context) {
                            final imgUrl = message.attachments.isNotEmpty
                                ? message.attachments.first.fileUrl
                                : (message.content != null && (message.content!.startsWith('http') || message.content!.startsWith('/uploads'))
                                    ? message.content!
                                    : '');
                            if (imgUrl.isEmpty) return const SizedBox.shrink();

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: imgUrl,
                                width: 220,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const SizedBox(
                                  height: 140,
                                  width: 220,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  height: 120,
                                  width: 220,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.broken_image, color: Colors.white54),
                                ),
                              ),
                            );
                          },
                        ),
                        if (message.content != null &&
                            message.content!.isNotEmpty &&
                            !message.content!.startsWith('http') &&
                            !message.content!.startsWith('/uploads'))
                          const SizedBox(height: 6),
                      ],

                      // Text Content
                      if (message.content != null &&
                          message.content!.isNotEmpty &&
                          (!message.isImage || (!message.content!.startsWith('http') && !message.content!.startsWith('/uploads'))))
                        Text(
                          message.content!,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                    ],
                  ),
                ),

                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallLogBubble(BuildContext context, bool isDark) {
    final content = message.content ?? 'Call ended';
    final isVideo = content.toLowerCase().contains('video');
    final isCancelled = content.toLowerCase().contains('cancelled') || content.toLowerCase().contains('missed');

    final IconData iconData;
    final Color iconColor;
    if (isVideo) {
      iconData = isCancelled ? Icons.missed_video_call_rounded : Icons.videocam_rounded;
      iconColor = isCancelled ? const Color(0xFFEF4444) : AppColors.brandSky;
    } else {
      iconData = isCancelled ? Icons.phone_missed_rounded : Icons.call_rounded;
      iconColor = isCancelled ? const Color(0xFFEF4444) : AppColors.statusOnline;
    }

    final timeStr = HaversineCalculator.formatRelativeTime(message.createdAt);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1B35).withValues(alpha: 0.95) : const Color(0xFFEDF2F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1E3258) : const Color(0xFFCBD5E1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.15),
              ),
              child: Icon(iconData, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
