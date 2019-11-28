import 'dart:ui';

import 'package:hsluv/hsluv.dart';

//extension on Color {
//  List<double> toRGBList() {
//    return [this.red.toDouble(), this.green.toDouble(), this.blue.toDouble()];
//  }
//}
//
//extension on List<double> {
//  Color toColor() {
//    return Color.fromARGB(1, this[0].toInt(), this[1].toInt(), this[2].toInt());
//  }
//}

List<double> toRGBList(Color color) {
  return [color.red.toDouble(), color.green.toDouble(), color.blue.toDouble()];
}

Color toColor(List<double> rgb) {
  return Color.fromARGB(255, (rgb[0] * 255).toInt(), (rgb[1] * 255).toInt(),
      (rgb[2] * 255).toInt());
}

/// HSLuv values are ranging in [0;360], [0;100] and [0;100] and RGB in [0;1].
/// @param tuple An array containing the color's HSL values in HSLuv color space.
/// @return A string containing a `#RRGGBB` representation of given color.
///*/
Color hsluvToRGBColor(List<double> tuple) {
  return toColor(Hsluv.hsluvToRgb(tuple));
}

Color hpluvToRGBColor(List<double> tuple) {
  return toColor(Hsluv.hpluvToRgb(tuple));
}
