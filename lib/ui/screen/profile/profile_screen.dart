import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../provider/auth_provider.dart';
import '../../widget/customer/customer_avatar.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _maxPhotoBytes = 2 * 1024 * 1024;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final p = auth.profile;
    if (p == null) {
      return const Scaffold(
        body: Center(child: Text('Authentication is required.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomerAvatar(
                    keyName: 'profileAvatar',
                    fullName: p.fullName,
                    photoUrl: p.photoUrl,
                    radius: 44,
                  ),
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: FloatingActionButton.small(
                      key: const Key('profilePhotoButton'),
                      heroTag: 'profile-photo-picker',
                      onPressed: auth.busy
                          ? null
                          : () => _showPhotoPicker(context),
                      child: auth.busy
                          ? const SizedBox(
                              key: Key('profilePhotoProgress'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(p.fullName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: auth.busy ? null : () => _showPhotoPicker(context),
              icon: const Icon(Icons.image_outlined),
              label: const Text('Change profile photo'),
            ),
            _row('Email', p.email),
            _row('Phone', p.phone),
            _row('Customer code', p.customerCode),
            _row('Customer type', p.customerType),
            if (p.address?.isNotEmpty ?? false) _row('Address', p.address!),
            if (p.city?.isNotEmpty ?? false) _row('City', p.city!),
            if (p.state?.isNotEmpty ?? false)
              _row('State / Division', p.state!),
            if (p.postalCode?.isNotEmpty ?? false)
              _row('Postal code', p.postalCode!),
            if (p.country?.isNotEmpty ?? false) _row('Country', p.country!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ),
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPhotoPicker(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || source == null) return;
    await _pickAndUpload(context, source);
  }

  Future<void> _pickAndUpload(BuildContext context, ImageSource source) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
      );
      if (!context.mounted || picked == null) return;
      final length = await picked.length();
      if (length > _maxPhotoBytes) {
        _message(messenger, 'Profile photo must be 2 MB or smaller.');
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!context.mounted) return;
      final ok = await auth.uploadProfilePhoto(
        bytes: bytes,
        filename: picked.name.isEmpty ? 'profile-photo.jpg' : picked.name,
      );
      if (!context.mounted) return;
      _message(
        messenger,
        ok
            ? 'Profile photo updated.'
            : auth.error ?? 'The profile photo could not be uploaded.',
      );
    } catch (_) {
      if (context.mounted) {
        _message(messenger, 'The selected photo could not be uploaded.');
      }
    }
  }

  void _message(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _row(String label, String value) =>
      ListTile(title: Text(label), subtitle: Text(value));
}
