import 'dart:math' as math;
import 'dart:ui';

import 'package:hsluv/hsluv.dart';

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

  /// Creates an [HSLuvColor] from an RGB [Color].
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
  /// It also accepts a [min] and [max] parameters, where default = 0, 100.
  HSLuvColor addSaturation(double add, {double min = 0, double max = 100}) {
    return HSLuvColor.fromHSL(
      hue,
      math.max(min, math.min(saturation + add, max)),
      lightness,
    );
  }

  /// Returns a copy of this color with saturation being added via the [add] parameter.
  /// It also accepts a [min] and [max] parameters, where default = 0, 100.
  HSLuvColor addLightness(double add, {double min = 0, double max = 100}) {
    return HSLuvColor.fromHSL(
      hue,
      saturation,
      math.max(min, math.min(lightness + add, max)),
    );
  }

  /// Returns a copy of this color with hue, saturation and lightness being added.
  /// If Saturation or Lightness values is > 100, it will be limited to 100.
  /// If Saturation or Lightness values is < 0, it will be set to 100.
  HSLuvColor addHSLuv(double h, double s, double l) {
    return HSLuvColor.fromHSL(
      (hue + h) % 360,
      math.max(0, math.min(saturation + s, 100)),
      math.max(0, math.min(lightness + l, 100)),
    );
  }

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
  String toString() => 'H:$hue S:$saturation L:$lightness';
}
