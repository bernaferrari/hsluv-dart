import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hsluv/hsluv.dart';
import 'dart:math' as math;

@immutable
class HSLuvColor {
  /// Creates a color.
  ///
  /// All the arguments must not be null and be in their respective ranges. See
  /// the fields for each parameter for a description of their ranges.
  const HSLuvColor.fromHSL(this.hue, this.saturation, this.lightness)
      : assert(hue != null),
        assert(saturation != null),
        assert(lightness != null),
        assert(hue >= 0.0),
        assert(hue <= 360.0),
        assert(saturation >= 0.0),
        assert(saturation <= 100.0),
        assert(lightness >= 0.0),
        assert(lightness <= 100.0);

  /// Creates an [HSLColor] from an RGB [Color].
  ///
  /// This constructor does not necessarily round-trip with [toColor] because
  /// of floating-point imprecision.
  factory HSLuvColor.fromColor(Color color) {
    final double red = color.red / 0xFF;
    final double green = color.green / 0xFF;
    final double blue = color.blue / 0xFF;

    final List<double> luv = Hsluv.rgbToHsluv([red, green, blue]);

    final double hue = luv[0].roundToDouble();
    final double saturation = luv[1].roundToDouble();
    final double lightness = luv[2].roundToDouble();

    return HSLuvColor.fromHSL(hue, saturation, lightness);
  }

  /// Hue, from 0.0 to 360.0. Describes which color of the spectrum is
  /// represented. A value of 0.0 represents red, as does 360.0. Values in
  /// between go through all the hues representable in RGB. You can think of
  /// this as selecting which color filter is placed over a light.
  final double hue;

  /// Saturation, from 0.0 to 1.0. This describes how colorful the color is.
  /// 0.0 implies a shade of grey (i.e. no pigment), and 1.0 implies a color as
  /// vibrant as that hue gets. You can think of this as the purity of the
  /// color filter over the light.
  final double saturation;

  /// Lightness, from 0.0 to 1.0. The lightness of a color describes how bright
  /// a color is. A value of 0.0 indicates black, and 1.0 indicates white. You
  /// can think of this as the intensity of the light behind the filter. As the
  /// lightness approaches 0.5, the colors get brighter and appear more
  /// saturated, and over 0.5, the colors start to become less saturated and
  /// approach white at 1.0.
  final double lightness;

  /// Returns a copy of this color with the [hue] parameter replaced with the
  /// given value.
  HSLuvColor withHue(double hue) {
    return HSLuvColor.fromHSL(hue, saturation, lightness);
  }

  /// Returns a copy of this color with the [saturation] parameter replaced with
  /// the given value.
  HSLuvColor withSaturation(double saturation) {
    return HSLuvColor.fromHSL(hue, math.min(saturation, 100), lightness);
  }

  /// Returns a copy of this color with the [lightness] parameter replaced with
  /// the given value.
  HSLuvColor withLightness(double lightness) {
    return HSLuvColor.fromHSL(hue, saturation, math.min(lightness, 100));
  }

  /// Returns this HSL color in RGB.
  Color toColor() {
    final rgb = Hsluv.hsluvToRgb([hue, saturation, lightness]);
    return Color.fromARGB(255, (rgb[0] * 255).toInt(), (rgb[1] * 255).toInt(),
        (rgb[2] * 255).toInt());
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! HSLuvColor) return false;
    final HSLuvColor typedOther = other;
    return typedOther.hue == hue &&
        typedOther.saturation == saturation &&
        typedOther.lightness == lightness;
  }

  @override
  int get hashCode => hashValues(hue, saturation, lightness);

  @override
  String toString() => '$runtimeType($hue, $saturation, $lightness)';
}
