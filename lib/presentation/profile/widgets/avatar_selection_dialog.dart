import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../shared/widgets/chunky_card.dart';
import '../providers/account_status_provider.dart';
import '../../home/providers/player_profile_provider.dart';

/// Menampilkan dialog popup pemilihan preset avatar pemain.
Future<String?> showAvatarSelectionDialog(
  BuildContext context, {
  String? currentAvatarId,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => AvatarSelectionDialog(currentAvatarId: currentAvatarId),
  );
}

/// Dialog pemilihan avatar bergaya Cozy Neobrutalism.
class AvatarSelectionDialog extends ConsumerStatefulWidget {
  const AvatarSelectionDialog({super.key, this.currentAvatarId});

  final String? currentAvatarId;

  @override
  ConsumerState<AvatarSelectionDialog> createState() =>
      _AvatarSelectionDialogState();
}

class _AvatarSelectionDialogState extends ConsumerState<AvatarSelectionDialog> {
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.currentAvatarId;
  }

  Future<void> _selectAvatar(String? avatarId) async {
    setState(() => _selectedId = avatarId);
    await ref.read(playerProfileProvider.notifier).updateAvatar(avatarId);
    if (mounted) {
      Navigator.of(context).pop(avatarId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountStatusProvider).valueOrNull;
    final initialLetter = (accountState != null && accountState.hasUsername)
        ? accountState.username![0].toUpperCase()
        : 'P';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ChunkyCard(
          variant: ChunkyCardVariant.woodBoard,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Avatar',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.colorEspresso,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.colorWoodMedium,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pilih avatar favoritmu untuk tampil di profil, peta, dan papan peringkat.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.colorTaupe,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),

              // Opsi 1: Gunakan Inisial Huruf (Default)
              InkWell(
                onTap: () => _selectAvatar(null),
                borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedId == null
                        ? AppTheme.colorHoney.withValues(alpha: 0.18)
                        : AppTheme.colorVanillaCard,
                    borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                    border: Border.all(
                      color: _selectedId == null
                          ? AppTheme.colorHoney
                          : AppTheme.colorWoodLight,
                      width: _selectedId == null ? 2.0 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.colorSage,
                          border: Border.all(
                            color: AppTheme.darkBorder,
                            width: AppTokens.borderWidthSubtle,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            initialLetter,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inisial Huruf Depan (Default)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppTheme.colorEspresso,
                              ),
                            ),
                            Text(
                              'Menampilkan huruf "$initialLetter"',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.colorTaupe,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedId == null)
                        const Icon(
                          AppIcons.check,
                          color: AppTheme.colorSage,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Grid 3x3 Preset Avatars
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: AppAssets.avatarPresets.length,
                  itemBuilder: (context, index) {
                    final assetPath = AppAssets.avatarPresets[index];
                    final avatarId = 'avatar_$index';
                    final isSelected = _selectedId == avatarId;

                    return GestureDetector(
                      onTap: () => _selectAvatar(avatarId),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppTheme.colorHoney.withValues(alpha: 0.25)
                                  : AppTheme.colorWoodPlank,
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.colorHoney
                                    : AppTheme.colorWoodMedium,
                                width: isSelected ? 3.0 : AppTokens.borderWidthSubtle,
                              ),
                              boxShadow: isSelected
                                  ? ChunkyShadow.wood(AppTheme.colorWoodDark)
                                  : null,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: ClipOval(
                              child: Image.asset(
                                assetPath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppTheme.colorSage,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  AppIcons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
