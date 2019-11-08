import 'package:flutter/material.dart';
import 'package:hsluv/flutter/hsluvcolor.dart';

extension on Color {
  List<double> toRGBList() {
    return [red / 255, green / 255, blue / 255];
  }
}

extension on List<double> {
  Color toColor() {
    return Color.fromARGB(255, (this[0] * 255).toInt(), (this[1] * 255).toInt(),
        (this[2] * 255).toInt());
  }
}

List<Color> hsluvAlternatives(Color color, [int n = 6]) {
  final HSLuvColor luv = HSLuvColor.fromColor(color);
  final int div = (360 / n).round();
  return [for (; n > 0; n--) luv.withHue((luv.hue + div * n) % 360).toColor()];
}

List<Color> hsluvTones(Color color,
    [int n = 6, double step = 0.15, double start = 0.1]) {
  final HSLuvColor hsv = HSLuvColor.fromColor(color);
  double sat = start;
  final List<Color> list = [];

  for (; n > 0; n--) {
    sat += step;
    if (sat > 100.0) {
      sat = 100.0;
    }

    list.add(hsv.withSaturation(sat).toColor());
  }

  return list.reversed.toList();
}

List<Color> hsluvLightness(Color color,
    [int n = 6, double step = 0.05, double start = 0.0]) {
  final HSLuvColor hsv = HSLuvColor.fromColor(color);
  double darkness = start;
  final List<Color> ret = [];

  for (; n > 0; n--) {
    darkness += step;
    if (darkness > 95.0) {
      darkness = 95.0;
    }

    ret.add(hsv.withLightness(darkness).toColor());
  }

  return ret.reversed.toList();
}
