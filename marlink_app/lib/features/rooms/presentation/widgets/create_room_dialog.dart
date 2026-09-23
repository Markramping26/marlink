import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/marlink_button.dart';
import '../../../../../core/widgets/marlink_text_field.dart';
import '../../providers/room_provider.dart';

class CreateRoomDialog extends ConsumerStatefulWidget {
  const CreateRoomDialog({super.key});

  @override
  ConsumerState<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<CreateRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final success = await ref.read(roomsNotifierProvider.notifier).createRoom(
          _nameController.text.trim(),
          _descController.text.trim().isNotEmpty ? _descController.text.trim() : null,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.statusOnline, size: 18),
                const SizedBox(width: 8),
                Text('Created "${_nameController.text.trim()}" successfully!'),
              ],
            ),
            backgroundColor: AppColors.darkSurface,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _error = ref.read(roomsNotifierProvider).errorMessage ?? 'Unable to create group.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Group', style: TextStyle(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a private group for your family, friends, travel companions, or team. A unique group code will be generated.',
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
                controller: _nameController,
                label: 'Group Name',
                hint: 'e.g. Family, Barkada, Team, Riders',
                prefixIcon: Icons.group_outlined,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Group name is required.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              MarLinkTextField(
                controller: _descController,
                label: 'Description (Optional)',
                hint: 'e.g. Daily location & safety check-in',
                prefixIcon: Icons.description_outlined,
                maxLines: 2,
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
          text: 'Create Group',
          width: 140,
          height: 44,
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
