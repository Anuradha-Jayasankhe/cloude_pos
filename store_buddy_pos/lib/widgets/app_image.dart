import 'dart:convert';
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

    // Check data URI (base64)
    if (raw.startsWith('data:image')) {
      try {
        final commaIdx = raw.indexOf(',');
        final base64Str = commaIdx != -1 ? raw.substring(commaIdx + 1) : raw;
        final bytes = base64Decode(base64Str);
        return _wrap(
          Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => err,
          ),
        );
      } catch (_) {
        return _wrap(err);
      }
    }

    // Check if it's a file:// URL or local filesystem path
    var localPath = raw;
    if (localPath.startsWith('file:///')) {
      localPath = Uri.decodeComponent(localPath.replaceFirst('file:///', ''));
    } else if (localPath.startsWith('file://')) {
      localPath = Uri.decodeComponent(localPath.replaceFirst('file://', ''));
    }

    if (!localPath.startsWith('http://') &&
        !localPath.startsWith('https://') &&
        !localPath.startsWith('/uploads') &&
        !localPath.startsWith('uploads')) {
      try {
        final file = File(localPath);
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
      } catch (_) {}
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
