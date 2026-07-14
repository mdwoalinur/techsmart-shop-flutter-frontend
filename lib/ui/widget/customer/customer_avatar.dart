import 'package:flutter/material.dart';
import '../../../service/config/app_environment.dart';
import '../../theme/app_colors.dart';

class CustomerAvatar extends StatelessWidget {
  const CustomerAvatar({
    required this.fullName,
    this.photoUrl,
    this.radius = 24,
    this.keyName,
    super.key,
  });

  final String fullName;
  final String? photoUrl;
  final double radius;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedPhotoUrl;
    final size = radius * 2;
    if (resolved == null) {
      return _fallback(context);
    }
    return ClipOval(
      key: keyName == null ? null : Key(keyName!),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          resolved,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(context, includeKey: false),
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : ColoredBox(
                  color: const Color(0xFFEAF1FA),
                  child: Center(
                    child: SizedBox(
                      width: radius * .55,
                      height: radius * .55,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  String? get _resolvedPhotoUrl {
    final raw = photoUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    return AppEnvironment.resolveBackendFileUrl(raw);
  }

  Widget _fallback(BuildContext context, {bool includeKey = true}) =>
      CircleAvatar(
        key: includeKey && keyName != null ? Key(keyName!) : null,
        radius: radius,
        backgroundColor: AppColors.electricBlue.withValues(alpha: .12),
        child: Text(
          _initial,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.electricBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  String get _initial {
    final trimmed = fullName.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }
}
