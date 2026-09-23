import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String text) onSendText;
  final Function(File image) onSendImage;
  final VoidCallback onSendLocation;
  final bool isSending;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendLocation,
    this.isSending = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  bool _showEmojiPicker = false;
  int _selectedCategoryIndex = 0;

  static const List<Map<String, dynamic>> _emojiCategories = [
    {
      'name': 'Smileys',
      'icon': '😀',
      'emojis': [
        '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
        '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😋',
        '😛', '😜', '🤪', '😝', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
        '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥', '😌', '😔',
        '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮', '🤧', '🥵',
        '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '🥸', '😎', '🤓', '🧐',
        '😕', '😟', '🙁', '😮', '😯', '😲', '😳', '🥺', '😦', '😧',
        '😨', '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞', '😓',
        '😩', '😫', '🥱', '😤', '😡', '😠', '🤬', '😈', '👿', '💀',
        '💩', '🤡', '👻', '👽', '🤖'
      ],
    },
    {
      'name': 'Gestures',
      'icon': '👍',
      'emojis': [
        '👍', '👎', '👏', '🙌', '👐', '🤲', '🤝', '🙏', '✌️', '🤞',
        '🤟', '🤘', '🤙', '👈', '👉', '👆', '🖕', '👇', '☝️', '👋',
        '🤚', '🖐️', '✋', '🖖', '👌', '🤌', '🤏', '✊', '👊', '🤛',
        '🤜', '✍️', '💅', '🤳', '💪', '🦾', '🦿', '🦵', '🦶', '👂',
        '👃', '👀', '👁️', '👅', '👄'
      ],
    },
    {
      'name': 'Travel & Safety',
      'icon': '📍',
      'emojis': [
        '📍', '🗺️', '🧭', '🚨', '🆘', '🛑', '⚠️', '🚸', '🚗', '🚕',
        '🚙', '🚌', '🏎️', '🚓', '🚑', '🚒', '🚐', '🛻', '🚚', '🚛',
        '🚜', '🏍️', '🛵', '🚲', '🛴', '⛽', '⚓', '⛵', '🚤', '🚢',
        '✈️', '🚁', '🏠', '🏡', '🏢', '🏥', '🏦', '🏪', '🏫', '🏯',
        '🏰', '🗼', '⛪', '⛺', '🏙️', '⚡', '🔥', '🌊', '🌧️', '❄️', '🛡️'
      ],
    },
    {
      'name': 'Hearts & Symbols',
      'icon': '❤️',
      'emojis': [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
        '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '🎉',
        '🎊', '🎈', '🎂', '🎁', '🏆', '🥇', '🥈', '🥉', '⭐', '🌟',
        '✨', '💫', '💥', '💯', '💢', '✅', '❌', '⭕', '❗', '❓',
        '‼️', '⁉️', '🎵', '🎶', '💡', '🔔'
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showEmojiPicker) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
  }

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Send Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.brandBlue),
                ),
                title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Take a picture using camera'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1600,
                    maxHeight: 1600,
                    imageQuality: 80,
                  );
                  if (picked != null) {
                    widget.onSendImage(File(picked.path));
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSky.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.brandSky),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select an image from device storage'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1600,
                    maxHeight: 1600,
                    imageQuality: 80,
                  );
                  if (picked != null) {
                    widget.onSendImage(File(picked.path));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
      setState(() => _showEmojiPicker = false);
    } else {
      FocusScope.of(context).unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  void _insertEmoji(String emoji) {
    final text = _controller.text;
    final selection = _controller.selection;
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + emoji.length),
      );
    } else {
      _controller.text = text + emoji;
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  void _backspace() {
    final text = _controller.text;
    if (text.isEmpty) return;
    final characters = text.characters;
    final newText = characters.skipLast(1).toString();
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newText.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primary Input Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  // Attach Location Button
                  IconButton(
                    icon: const Icon(Icons.add_location_alt_outlined),
                    tooltip: 'Location Sharing & Privacy',
                    color: isDark ? AppColors.brandSky : AppColors.brandBlue,
                    onPressed: widget.onSendLocation,
                  ),

                  // Attach Image Button
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Send Image',
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    onPressed: _pickImage,
                  ),

                  // Emoji Toggle Button
                  IconButton(
                    icon: Icon(
                      _showEmojiPicker
                          ? Icons.keyboard_alt_outlined
                          : Icons.sentiment_satisfied_alt_outlined,
                    ),
                    tooltip: _showEmojiPicker ? 'Show Keyboard' : 'Emojis',
                    color: _showEmojiPicker
                        ? AppColors.brandSky
                        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    onPressed: _toggleEmojiPicker,
                  ),

                  // Text Input Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message room...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send Button
                  widget.isSending
                      ? const SizedBox(
                          width: 38,
                          height: 38,
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton.filled(
                          onPressed: _handleSend,
                          icon: const Icon(Icons.send_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? AppColors.brandSky : AppColors.brandBlue,
                            foregroundColor: isDark ? AppColors.brandNavy : Colors.white,
                          ),
                        ),
                ],
              ),
            ),

            // 3. Expandable Categorized Emoji Picker Tray
            if (_showEmojiPicker) ...[
              Container(
                height: 250,
                color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF1F5F9),
                child: Column(
                  children: [
                    // Category Selector Tabs
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: _emojiCategories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                              itemBuilder: (context, idx) {
                                final cat = _emojiCategories[idx];
                                final isSel = _selectedCategoryIndex == idx;
                                return InkWell(
                                  onTap: () => setState(() => _selectedCategoryIndex = idx),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: isSel
                                          ? const Border(
                                              bottom: BorderSide(
                                                color: AppColors.brandSky,
                                                width: 2.5,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(cat['icon'], style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Text(
                                          cat['name'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                            color: isSel
                                                ? AppColors.brandSky
                                                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Backspace Button
                          IconButton(
                            icon: const Icon(Icons.backspace_outlined, size: 18),
                            tooltip: 'Backspace',
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            onPressed: _backspace,
                          ),
                        ],
                      ),
                    ),

                    // Grid of Emojis
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                        itemCount: (_emojiCategories[_selectedCategoryIndex]['emojis'] as List<String>).length,
                        itemBuilder: (context, index) {
                          final emoji = (_emojiCategories[_selectedCategoryIndex]['emojis'] as List<String>)[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _insertEmoji(emoji),
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
