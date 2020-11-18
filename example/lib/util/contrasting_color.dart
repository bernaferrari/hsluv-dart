
import 'package:flutter/material.dart';
import 'package:hsluv/hsluvcolor.dart';

import 'constants.dart';

Color contrastingRGBColor(Color color) {
  return (color.computeLuminance() > kLumContrast)
      ? Colors.black
      : Colors.white;
}

Color contrastingHSLuvColor(HSLuvColor hsLuvColor) {
  return (hsLuvColor.lightness > kLightnessThreshold)
      ? Colors.black
      : Colors.white;
}
