import 'package:flutter/material.dart';

class FeaturedImage extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const FeaturedImage({super.key,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
            progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image)),
          ),
        ),
      ),
    );
  }
}

class ImageTile extends StatelessWidget {
  final String url;
  final VoidCallback onTap;

  const ImageTile({super.key,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) =>
          progress == null
              ? child
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }
}