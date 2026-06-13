import 'dart:typed_data';

import 'package:crosscue/features/challenge_boards/data/services/avatar_photo_cache.dart';
import 'package:crosscue/features/challenge_boards/domain/models/challenge_models.dart';
import 'package:crosscue/features/challenge_boards/presentation/providers/challenge_board_providers.dart';
import 'package:crosscue/features/challenge_boards/presentation/theme/app_colors.dart';
import 'package:crosscue/features/challenge_boards/presentation/widgets/avatar/preset_avatars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Crosscue · Player avatar widget.
///
/// Renders, by [PlayerAvatar.kind]:
///   • initials  → tinted disc with the player's initials
///   • silhouette → one of the preset looks (see kPresetAvatars)
///   • photo      → the player's normalized circular image, from in-memory
///     bytes (decoded `data:` URLs) or an `https:` URL fetched through
///     [AvatarPhotoCache] (#268). While loading — and on any fetch failure —
///     the initials disc shows instead, exactly like a missing photo.
class PlayerAvatarView extends StatelessWidget {
  final PlayerAvatar avatar;
  final String name;
  final double size;
  const PlayerAvatarView({
    super.key,
    required this.avatar,
    required this.name,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    switch (avatar.kind) {
      case AvatarKind.silhouette:
        return PresetAvatar(look: avatar.silhouetteLook, size: size);
      case AvatarKind.photo:
        final bytes = avatar.photoBytes;
        if (bytes != null) return _photo(bytes);
        final url = avatar.photoUrl;
        // Defense in depth: the API layer already rejects non-https,
        // non-data photo URLs, but never hand an arbitrary scheme to the
        // network stack.
        if (url == null || !url.startsWith('https://')) {
          return _initialsDisc(context);
        }
        return Consumer(
          builder: (context, ref, _) => _RemotePhotoAvatar(
            cache: ref.watch(avatarPhotoCacheProvider),
            url: url,
            size: size,
            fallback: _initialsDisc(context),
          ),
        );
      case AvatarKind.initials:
        return _initialsDisc(context);
    }
  }

  Widget _photo(Uint8List bytes) {
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }

  Widget _initialsDisc(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer(context),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials(name),
        style: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
          letterSpacing: -0.5,
          color: AppColors.primary(context),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((w) => w.isEmpty ? '' : w[0]).join();
    return letters.toUpperCase();
  }
}

/// Renders an `https:` avatar photo via [AvatarPhotoCache]: cached bytes show
/// immediately; otherwise [fallback] shows quietly until the fetch resolves
/// (pop-in on success, stays on failure — no spinner, no error surface).
class _RemotePhotoAvatar extends StatelessWidget {
  const _RemotePhotoAvatar({
    required this.cache,
    required this.url,
    required this.size,
    required this.fallback,
  });

  final AvatarPhotoCache cache;
  final String url;
  final double size;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final cached = cache.cached(url);
    if (cached != null) return _photo(cached);
    return FutureBuilder<Uint8List?>(
      // Safe to create in build: the cache memoizes in-flight fetches per
      // URL, so rebuilds reuse the same future instead of refetching.
      future: cache.load(url),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return bytes == null ? fallback : _photo(bytes);
      },
    );
  }

  Widget _photo(Uint8List bytes) {
    return ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }
}
