import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/marlink_button.dart';
import '../../../../../core/widgets/marlink_text_field.dart';
import '../../providers/room_provider.dart';

class JoinRoomDialog extends ConsumerStatefulWidget {
  const JoinRoomDialog({super.key});

  @override
  ConsumerState<JoinRoomDialog> createState() => _JoinRoomDialogState();
}

class _JoinRoomDialogState extends ConsumerState<JoinRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final success = await ref.read(roomsNotifierProvider.notifier).joinRoom(
          _codeController.text.trim().toUpperCase(),
          _nicknameController.text.trim().isNotEmpty ? _nicknameController.text.trim() : null,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.statusOnline, size: 18),
                SizedBox(width: 8),
                Text('Joined group successfully!'),
              ],
            ),
            backgroundColor: AppColors.darkSurface,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _error = ref.read(roomsNotifierProvider).errorMessage ?? 'Unable to join group.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a Group', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the 6-character group invite code shared by your group administrator.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              MarLinkTextField(
                controller: _codeController,
                label: 'Group Code',
                hint: 'e.g. FAM-82K4',
                prefixIcon: Icons.vpn_key_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter the group code.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              MarLinkTextField(
                controller: _nicknameController,
                label: 'Your Nickname in this Group (Optional)',
                hint: 'e.g. Dad, Mom, Captain, Rider 1',
                prefixIcon: Icons.badge_outlined,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        MarLinkButton(
          text: 'Join Group',
          width: 120,
          height: 44,
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
