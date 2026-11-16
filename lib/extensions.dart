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

/// HSLuv values are ranging in [0;360], [0;100] and [0;100] and RGB in [0;1].
Color hsluvToRGBColor(List<double> tuple) {
  return toColor(Hsluv.hsluvToRgb(tuple));
}

Color hpluvToRGBColor(List<double> tuple) {
  return toColor(Hsluv.hpluvToRgb(tuple));
}
