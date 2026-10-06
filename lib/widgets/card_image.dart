import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';

bool isNetworkImage(String path) =>
    path.startsWith('http://') || path.startsWith('https://');

class CardImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final bool thumbnail;
  final int? cacheWidth;

  const CardImage({
    super.key,
    required this.path,
    this.fit = BoxFit.contain,
    this.thumbnail = false,
    this.cacheWidth,
  });

  static const _pokemonTcgHost = 'https://images.pokemontcg.io/';

  static String smallVariant(String url) =>
      url.startsWith(_pokemonTcgHost) ? url.replaceFirst('_hires.png', '.png') : url;

  @override
  Widget build(BuildContext context) {
    if (!isNetworkImage(path)) {
      return Image.asset(
        path,
        fit: fit,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => const _ArtworkPlaceholder(),
      );
    }
    return Image.network(
      thumbnail ? smallVariant(path) : path,
      fit: fit,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _ArtworkPlaceholder(loading: true),
      errorBuilder: (_, __, ___) => const _ArtworkPlaceholder(),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  final bool loading;

  const _ArtworkPlaceholder({this.loading = false});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: PokeBinderColors.slateGradient),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                Icons.image_not_supported_outlined,
                size: 20,
                color: PokeBinderColors.ink.withValues(alpha: 0.35),
              ),
      ),
    );
  }
}
