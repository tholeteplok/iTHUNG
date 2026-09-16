import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../shared/widgets/app_error_banner.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/chunky_card.dart';
import '../providers/account_status_provider.dart';

/// Menampilkan notifikasi selamat datang kembali kepada pemain yang sudah memiliki akun/username.
void showWelcomeBackGreeting(BuildContext context, String username) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Selamat datang kembali, petualang $username!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTheme.colorWoodDark,
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Menangani alur setelah proses sign-in berhasil:
/// - Jika akun belum memiliki username, tampilkan [showSetUsernameDialog].
/// - Jika akun sudah memiliki username, tampilkan pesan sambutan [showWelcomeBackGreeting].
Future<void> handlePostSignInFlow(
  BuildContext context,
  WidgetRef ref, {
  AccountState? accountState,
}) async {
  if (!context.mounted) return;
  final AccountState state = accountState ??
      await ref.read(accountStatusProvider.future);
  if (!context.mounted) return;
  if (!state.hasUsername) {
    await showSetUsernameDialog(context);
  } else {
    showWelcomeBackGreeting(context, state.username!);
  }
}

/// Menampilkan dialog popup pembuatan/pengubahan username pemain.
Future<String?> showSetUsernameDialog(
  BuildContext context, {
  String? currentUsername,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SetUsernameDialog(currentUsername: currentUsername),
  );
}

/// Dialog taktil untuk menetapkan username pemain (minimal 4 karakter).
class SetUsernameDialog extends ConsumerStatefulWidget {
  const SetUsernameDialog({super.key, this.currentUsername});

  final String? currentUsername;

  @override
  ConsumerState<SetUsernameDialog> createState() => _SetUsernameDialogState();
}

class _SetUsernameDialogState extends ConsumerState<SetUsernameDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUsername ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim();
    if (raw.length < 4) {
      setState(() {
        _errorMessage = 'Username minimal 4 karakter.';
      });
      return;
    }

    final validPattern = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!validPattern.hasMatch(raw)) {
      setState(() {
        _errorMessage = 'Gunakan hanya huruf, angka, dan garis bawah (_).';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref.read(accountStatusProvider.notifier).setUsername(raw);

    if (!mounted) return;

    if (result is RepoSuccess<void>) {
      Navigator.of(context).pop(raw);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = (result as RepoFailure).reason;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.currentUsername != null && widget.currentUsername!.length >= 4,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ChunkyCard(
          variant: ChunkyCardVariant.vanillaSoft,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                AppIcons.profile,
                color: AppTheme.colorSage,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                'Buat Username',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.colorEspresso,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Username ini akan tampil di papan peringkat alih-alih email pribadimu (min. 4 karakter).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.colorTaupe,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 16,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Contoh: petualang_1',
                  prefixText: '@',
                  prefixStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.colorWoodMedium,
                    fontSize: 16,
                  ),
                  filled: true,
                  fillColor: AppTheme.colorVanillaCard,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    borderSide: const BorderSide(
                      color: AppTheme.darkBorder,
                      width: AppTokens.borderWidthDefault,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    borderSide: const BorderSide(
                      color: AppTheme.darkBorder,
                      width: AppTokens.borderWidthDefault,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                    borderSide: const BorderSide(
                      color: AppTheme.colorWoodDark,
                      width: AppTokens.borderWidthSubtle,
                    ),
                  ),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.colorEspresso,
                  fontSize: 16,
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                AppErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 20),
              ChunkyButton(
                onPressed: _isLoading ? null : _submit,
                backgroundColor: AppTheme.colorSage,
                borderColor: const Color(0xFF43733A),
                shadowColor: const Color(0xFF43733A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Text(
                        'Simpan & Lanjutkan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.currentUsername != null && widget.currentUsername!.length >= 4) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: AppTheme.colorTaupe,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
