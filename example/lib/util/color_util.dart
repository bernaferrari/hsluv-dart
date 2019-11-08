import 'package:flutter/material.dart';

Color compositeColors(Color foreground, Color background, double overlay) {
  assert(overlay <= 1.0);
  final colorForeground = foreground.withOpacity(overlay);
  return Color.alphaBlend(colorForeground, background);
}

Color blendColorWithBackground(Color color,
    [Color background = const Color(0xff121212)]) {
  return Color.alphaBlend(color.withOpacity(0.08), background);
}

String colorToHexStr(Color color) =>
    "#${color.value.toRadixString(16).substring(2)}";

String colorToStr(Color color) =>
    "${color.value.toRadixString(16).substring(2)}";