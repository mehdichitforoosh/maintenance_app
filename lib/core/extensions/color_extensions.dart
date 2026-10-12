import 'package:flutter/material.dart';

extension ColorExtension on Color {
  /// Darkens the color by a [percent] (0-100)
  Color darken([int percent = 10]) {
    assert(0 <= percent && percent <= 100);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - percent / 100).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Lightens the color by a [percent] (0-100)
  Color lighten([int percent = 10]) {
    assert(0 <= percent && percent <= 100);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + percent / 100).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
