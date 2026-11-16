import 'dart:ui';

import 'package:hsluv/hsluv.dart';

extension HSLuvColorExtension on Color {
  /// Converts this [Color] to an [HSLuvColor].
  ///
  /// Rounds components by default; pass `round: false` or call [toRawHSLuv] to
  /// keep full floating-point precision.
  HSLuvColor toHSLuv({bool round = true}) =>
      HSLuvColor.fromColor(this, round: round);

  /// Converts this [Color] to an [HSLuvColor] without rounding channels.
  HSLuvColor toRawHSLuv() => HSLuvColor.fromRawColor(this);
}

List<double> toRGBList(Color color) {
  return [
    (color.r * 255.0).round().clamp(0, 255).toDouble(),
    (color.g * 255.0).round().clamp(0, 255).toDouble(),
    (color.b * 255.0).round().clamp(0, 255).toDouble(),
  ];
}

Color toColor(List<double> rgb) {
  return Color.fromARGB(
    255,
    (rgb[0] * 255).round().clamp(0, 255),
    (rgb[1] * 255).round().clamp(0, 255),
    (rgb[2] * 255).round().clamp(0, 255),
  );
}

/// Converts an HSLuv `[H, S, L]` tuple (`H` in `0..360`, `S` and `L` in
/// `0..100`) to an opaque Flutter [Color].
Color hsluvToRGBColor(List<double> tuple) {
  return toColor(Hsluv.hsluvToRgb(tuple));
}

/// Converts an HPLuv `[H, S, L]` tuple (`H` in `0..360`, `S` and `L` in
/// `0..100`) to an opaque Flutter [Color].
Color hpluvToRGBColor(List<double> tuple) {
  return toColor(Hsluv.hpluvToRgb(tuple));
}
