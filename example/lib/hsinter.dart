import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hsluv/flutter/hsluvcolor.dart';
import 'package:hsluvsample/hsluv_selector.dart';

@immutable
class HSInterColor {
  /// Creates a color.
  ///
  /// All the arguments must not be null and be in their respective ranges. See
  /// the fields for each parameter for a description of their ranges.
  const HSInterColor.fromHSInter(
      this.hue, this.saturation, this.lightness, this.kind, this.maxValue)
      : assert(hue != null),
        assert(saturation != null),
        assert(lightness != null);

  /// Creates an [HSInterColor] from an RGB [Color].
  ///
  /// This constructor does not necessarily round-trip with [toColor] because
  /// of floating-point imprecision.
  factory HSInterColor.fromColor(Color color, String kind) {
    final double maxV = when({
      () => kind == "HSLuv": () => 100.0,
      () => kind == "HSV": () => 1.0,
    }, orElse: () => 0.0);

    if (kind == "HSLuv") {
      final luv = HSLuvColor.fromColor(color);
      return HSInterColor.fromHSInter(
          luv.hue, luv.saturation, luv.lightness, kind, maxV);
    } else if (kind == "HSV") {
      final hsv = HSVColor.fromColor(color);
      return HSInterColor.fromHSInter(
          hsv.hue, hsv.saturation, hsv.value, kind, maxV);
    } else {
      final hsv = HSVColor.fromColor(color);
      return HSInterColor.fromHSInter(
          hsv.hue, hsv.saturation, hsv.value, kind, maxV);
    }
  }

  final String kind;
  final double hue;
  final double saturation;
  final double lightness;
  final double maxValue;

  int outputSaturation() {
    return when({
      () => kind == "HSLuv": () => saturation,
      () => kind == "HSV": () => saturation * 100,
    }).toInt();
  }

  int outputLightness() {
    return when({
      () => kind == "HSLuv": () => lightness,
      () => kind == "HSV": () => lightness * 100,
    }).toInt();
  }

  /// Returns a copy of this color with the [hue] parameter replaced with the
  /// given value.
  HSInterColor withHue(double hue) {
    return HSInterColor.fromHSInter(hue, saturation, lightness, kind, maxValue);
  }

  /// Returns a copy of this color with the [saturation] parameter replaced with
  /// the given value.
  HSInterColor withSaturation(double saturation) {
    return HSInterColor.fromHSInter(
        hue, math.min(saturation, maxValue), lightness, kind, maxValue);
  }

  /// Returns a copy of this color with the [lightness] parameter replaced with
  /// the given value.
  HSInterColor withLightness(double lightness) {
    return HSInterColor.fromHSInter(
        hue, saturation, math.min(lightness, maxValue), kind, maxValue);
  }

  /// Returns this HSL color in RGB.
  Color toColor() {
    return when({
      () => kind == "HSLuv": () =>
          HSLuvColor.fromHSL(hue, saturation, lightness).toColor(),
      () => kind == "HSV": () =>
          HSVColor.fromAHSV(1.0, hue, saturation, lightness).toColor(),
    });
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! HSInterColor) return false;
    final HSInterColor typedOther = other;
    return typedOther.hue == hue &&
        typedOther.saturation == saturation &&
        typedOther.lightness == lightness;
  }

  @override
  int get hashCode => hashValues(hue, saturation, lightness);

  @override
  String toString() {
    return when({
      () => kind == "HSLuv": () =>
          "H:${hue.toInt()} S:${outputSaturation()} L:${outputLightness()}",
      () => kind == "HSV": () =>
          "H: ${hue.toInt()} S:${outputSaturation()} V:${outputLightness()}",
    });
  }
}
