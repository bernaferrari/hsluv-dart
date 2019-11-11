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
  // in the original, code it is: luv.hue + (div * n) % 360
  // this was modified to ignore luv.hue value because the
  // list that is observing would miss the current position every time
  // the color changes.
  return [for (; n > 0; n--) luv.withHue((div * n) % 360.0).toColor()];
}

List<Color> hsluvTones(Color color, [double step = 5.0, double start = 100.0]) {
  final HSLuvColor hsluv = HSLuvColor.fromColor(color);

  return [
    for (double sat = start; sat > 0; sat -= step)
      hsluv.withSaturation(sat).toColor()
  ];
}

List<Color> hsluvLightness(Color color,
    [double step = 5.0, double start = 100.0]) {
  final HSLuvColor hsluv = HSLuvColor.fromColor(color);

  return [
    for (double light = start; light > 0; light -= step)
      hsluv.withLightness(light).toColor()
  ];
}
