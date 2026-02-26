import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// User Avatar with initials fallback
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? backgroundColor;
  final bool showBorder;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = AppSpacing.avatarSizeMedium,
    this.backgroundColor,
    this.showBorder = false,
    this.isOnline = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color get _bgColor {
    if (backgroundColor != null) return backgroundColor!;
    // Generate consistent color based on name
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFFA78BFA),
      const Color(0xFFF472B6),
      const Color(0xFF60A5FA),
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _bgColor.withOpacity(0.15),
            border: showBorder
                ? Border.all(color: AppColors.cardBackground, width: 2)
                : null,
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: _bgColor,
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBackground, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// Avatar Group (for showing multiple avatars stacked)
class AvatarGroup extends StatelessWidget {
  final List<AvatarData> avatars;
  final int maxShow;
  final double size;
  final double overlap;

  const AvatarGroup({
    super.key,
    required this.avatars,
    this.maxShow = 4,
    this.size = 32,
    this.overlap = 8,
  });

  @override
  Widget build(BuildContext context) {
    final showCount = avatars.length > maxShow ? maxShow : avatars.length;
    final remaining = avatars.length - maxShow;

    return SizedBox(
      width:
          (size * showCount) -
          (overlap * (showCount - 1)) +
          (remaining > 0 ? size - overlap : 0),
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < showCount; i++)
            Positioned(
              left: (size - overlap) * i,
              child: UserAvatar(
                name: avatars[i].name,
                imageUrl: avatars[i].imageUrl,
                size: size,
                showBorder: true,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: (size - overlap) * showCount,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBackground, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: size * 0.32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AvatarData {
  final String name;
  final String? imageUrl;

  const AvatarData({required this.name, this.imageUrl});
}
