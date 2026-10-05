import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../theme/pokebinder_theme.dart';

class TrainerAvatar extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double size;
  final double iconSize;
  final double borderWidth;
  final List<BoxShadow>? shadow;

  const TrainerAvatar({
    super.key,
    this.imageUrl,
    this.imageBytes,
    required this.size,
    required this.iconSize,
    this.borderWidth = 2,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.catching_pokemon,
      size: iconSize,
      color: PokeBinderColors.white,
    );
    final bytes = imageBytes;
    final url = imageUrl;
    final Widget child;
    if (bytes != null) {
      child = Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (url != null) {
      child = Stack(
        fit: StackFit.expand,
        children: [
          Center(child: fallback),
          Image.network(
            url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
            frameBuilder: (context, image, frame, loadedSynchronously) {
              if (loadedSynchronously) return image;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: image,
              );
            },
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ],
      );
    } else {
      child = fallback;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PokeBinderColors.redGradient,
        boxShadow: shadow,
      ),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: PokeBinderColors.gold, width: borderWidth),
      ),
      child: child,
    );
  }
}
