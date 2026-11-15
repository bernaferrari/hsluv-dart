import 'dart:math' as math;
import 'dart:ui';

import 'package:hsluv/hsluv.dart';

class HSLuvColor {
  /// Creates a color.
  ///
  /// All the arguments must not be null and be in their respective ranges. See
  /// the fields for each parameter for a description of their ranges.
  const HSLuvColor.fromHSL(this.hue, this.saturation, this.lightness)
      : assert(hue >= 0.0),
        assert(hue <= 360.0),
        assert(saturation >= 0.0),
        assert(saturation <= 100.0),
        assert(lightness >= 0.0),
        assert(lightness <= 100.0);

  /// Creates an [HSLuvColor] from an RGB [Color].
  ///
  /// When [round] is true (default), components are rounded to the nearest
  /// integer. Pass `round: false` or use [HSLuvColor.fromRawColor] to preserve
  /// full floating-point precision.
  factory HSLuvColor.fromColor(Color color, {bool round = true}) {
    final double red = color.r.clamp(0.0, 1.0);
    final double green = color.g.clamp(0.0, 1.0);
    final double blue = color.b.clamp(0.0, 1.0);

    final List<double> luv = Hsluv.rgbToHsluv([red, green, blue]);

    final double hue =
        (round ? luv[0].roundToDouble() : luv[0]).clamp(0.0, 360.0);
    final double saturation =
        (round ? luv[1].roundToDouble() : luv[1]).clamp(0.0, 100.0);
    final double lightness =
        (round ? luv[2].roundToDouble() : luv[2]).clamp(0.0, 100.0);

    return HSLuvColor.fromHSL(hue, saturation, lightness);
  }

  /// Creates an [HSLuvColor] from an RGB [Color] preserving floating-point
  /// precision.
  factory HSLuvColor.fromRawColor(Color color) =>
      HSLuvColor.fromColor(color, round: false);

  /// Hue, from 0.0 to 360.0. Describes which color of the spectrum is
  /// represented. A value of 0.0 represents red, as does 360.0. Values in
  /// between go through all the hues representable in RGB. You can think of
  /// this as selecting which color filter is placed over a light.
  final double hue;

  /// Saturation, from 0.0 to 100.0. This describes how colorful the color is.
  /// 0.0 implies a shade of grey (i.e. no pigment), and 100.0 implies a color as
  /// vibrant as that hue gets. You can think of this as the purity of the
  /// color filter over the light.
  final double saturation;

  /// Lightness, from 0.0 to 100.0. The lightness of a color describes how bright
  /// a color is. A value of 0.0 indicates black, and 100.0 indicates white.
  final double lightness;

  /// Returns a copy of this color with hue being added via the [add] parameter.
  /// It also accepts a [cycle] parameter, so it circles back when larger than it (default = 360).
  HSLuvColor addHue(double add, [int cycle = 360]) {
    return HSLuvColor.fromHSL((hue + add) % cycle, saturation, lightness);
  }

  /// Returns a copy of this color with saturation being added via the [add] parameter.
  /// It also accepts [min] and [max] parameters, where default = 0, 100.
  HSLuvColor addSaturation(double add, {double min = 0, double max = 100}) {
    return HSLuvColor.fromHSL(
      hue,
      math.max(min, math.min(saturation + add, max)),
      lightness,
    );
  }

  /// Returns a copy of this color with lightness being added via the [add] parameter.
  /// It also accepts [min] and [max] parameters, where default = 0, 100.
  HSLuvColor addLightness(double add, {double min = 0, double max = 100}) {
    return HSLuvColor.fromHSL(
      hue,
      saturation,
      math.max(min, math.min(lightness + add, max)),
    );
  }

  /// Returns a copy of this color with hue, saturation and lightness being added.
  /// If Saturation or Lightness values is > 100, it will be limited to 100.
  /// If Saturation or Lightness values is < 0, it will be set to 0.
  HSLuvColor addHSLuv(double h, double s, double l) {
    return HSLuvColor.fromHSL(
      (hue + h) % 360,
      math.max(0, math.min(saturation + s, 100)),
      math.max(0, math.min(lightness + l, 100)),
    );
  }

  /// Returns a copy of this color with the specified fields replaced.
  HSLuvColor copyWith({
    double? hue,
    double? saturation,
    double? lightness,
  }) {
    return HSLuvColor.fromHSL(
      (hue ?? this.hue).clamp(0.0, 360.0),
      (saturation ?? this.saturation).clamp(0.0, 100.0),
      (lightness ?? this.lightness).clamp(0.0, 100.0),
    );
  }

  /// Returns a copy of this color with the [hue] parameter replaced with the
  /// given value.
  HSLuvColor withHue(double hue) {
    return HSLuvColor.fromHSL(hue.clamp(0.0, 360.0), saturation, lightness);
  }

  /// Returns a copy of this color with the [saturation] parameter replaced with
  /// the given value.
  HSLuvColor withSaturation(double saturation) {
    return HSLuvColor.fromHSL(hue, saturation.clamp(0.0, 100.0), lightness);
  }

  /// Returns a copy of this color with the [lightness] parameter replaced with
  /// the given value.
  HSLuvColor withLightness(double lightness) {
    return HSLuvColor.fromHSL(hue, saturation, lightness.clamp(0.0, 100.0));
  }

  /// Returns this HSLuv color as an sRGB [Color].
  Color toColor() {
    final rgb = Hsluv.hsluvToRgb([hue, saturation, lightness]);
    return Color.fromARGB(
      255,
      (rgb[0] * 255).round().clamp(0, 255),
      (rgb[1] * 255).round().clamp(0, 255),
      (rgb[2] * 255).round().clamp(0, 255),
    );
  }

  /// Returns a `#RRGGBB` hex string for this color.
  String toHex() => Hsluv.hsluvToHex([hue, saturation, lightness]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HSLuvColor &&
        other.hue == hue &&
        other.saturation == saturation &&
        other.lightness == lightness;
  }

  @override
  int get hashCode => Object.hash(hue, saturation, lightness);

  @override
  String toString() => 'H:$hue S:$saturation L:$lightness';
}
