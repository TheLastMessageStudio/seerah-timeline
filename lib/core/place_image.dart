import 'package:flutter/material.dart';
import '../data/models.dart';
import '../l10n/strings.dart';

String placeImageCaption(Place place) {
  if (place.imageAsset != null) {
    return switch (Strings.lang) {
      'en' => place.imageAssetCaptionEn ?? place.imageAssetCaptionFr ?? '',
      'ar' => place.imageAssetCaptionAr ?? place.imageAssetCaptionFr ?? '',
      _ => place.imageAssetCaptionFr ?? '',
    };
  }
  return place.imageCaptionFr ?? '';
}

String placeImageCreditLine(Place place) {
  if (place.imageAsset != null) {
    return switch (Strings.lang) {
      'en' => 'Original AI-generated illustration · educational artwork, not documentary',
      'ar' => 'رسم توضيحي مولّد بالذكاء الاصطناعي · مادة تعليمية غير توثيقية',
      _ => 'Illustration originale générée par IA · visuel pédagogique non documentaire',
    };
  }
  return '${place.imageCredit ?? ''} · ${place.imageLicense ?? ''}';
}

class PlaceImage extends StatelessWidget {
  final Place place;
  final double? width;
  final double height;
  final BoxFit fit;

  const PlaceImage({
    super.key,
    required this.place,
    this.width,
    this.height = 180,
    this.fit = BoxFit.cover,
  });

  Widget _placeholder(BuildContext context) => Container(
    width: width,
    height: height,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 34)),
  );

  @override
  Widget build(BuildContext context) {
    final asset = place.imageAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => place.imageUrl == null
            ? _placeholder(context)
            : Image.network(
                place.imageUrl!,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (_, __, ___) => _placeholder(context),
              ),
      );
    }
    if (place.imageUrl != null && place.imageUrl!.isNotEmpty) {
      return Image.network(
        place.imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }
    return _placeholder(context);
  }
}
