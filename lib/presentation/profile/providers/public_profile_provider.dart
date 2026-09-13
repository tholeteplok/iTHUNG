import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/public_profile.dart';
import '../../../domain/repositories/repo_result.dart';
import '../../game/providers/game_dependencies_provider.dart';

/// Provider untuk memuat data profil publik pemain (view-only) secara asinkron berdasarkan [username].
final publicProfileProvider =
    FutureProvider.autoDispose.family<RepoResult<PublicProfile?>, String>((
  ref,
  username,
) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchPublicProfile(username);
});
