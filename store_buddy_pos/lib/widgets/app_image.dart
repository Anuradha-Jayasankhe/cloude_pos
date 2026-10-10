import 'dart:io';
import 'package:flutter/material.dart';

import '../services/api_client.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    Widget fallback = placeholder ??
        Container(
          width: width,
          height: height,
          color: Colors.black.withValues(alpha: 0.05),
          alignment: Alignment.center,
          child: Icon(
            Icons.image_outlined,
            size: (width != null && width! < 40) ? 18 : 24,
            color: Colors.grey[400],
          ),
        );

    Widget err = errorWidget ?? fallback;

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _wrap(fallback);
    }

    final raw = imageUrl!.trim();

    // Check if it's a local file path that exists on this machine
    if (!raw.startsWith('http://') &&
        !raw.startsWith('https://') &&
        !raw.startsWith('/uploads') &&
        !raw.startsWith('uploads')) {
      final file = File(raw);
      if (file.existsSync()) {
        return _wrap(
          Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => err,
          ),
        );
      }
    }

    // Resolve URL via ApiClient
    final fullUrl = ApiClient.resolveImageUrl(raw);

    if (fullUrl.startsWith('http://') || fullUrl.startsWith('https://')) {
      return _wrap(
        Image.network(
          fullUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return fallback;
          },
          errorBuilder: (context, error, stackTrace) => err,
        ),
      );
    }

    // Fallback if local file couldn't be loaded or path is unknown
    return _wrap(err);
  }

  Widget _wrap(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }
}
