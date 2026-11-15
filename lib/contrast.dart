/* See math/contrast.wxm */

import 'hsluv.dart';

class Contrast {
  // ignore: constant_identifier_names
  static const W3C_CONTRAST_TEXT = 4.5;
  // ignore: constant_identifier_names
  static const W3C_CONTRAST_LARGE_TEXT = 3.0;

  static double contrastRatio(double lighterL, double darkerL) {
    // https://www.w3.org/TR/WCAG20-TECHS/G18.html#G18-procedure
    final lighterY = Hsluv.lToY(lighterL);
    final darkerY = Hsluv.lToY(darkerL);
    return (lighterY + 0.05) / (darkerY + 0.05);
  }

  static double lighterMinL(double r) {
    return Hsluv.yToL((r - 1) / 20);
  }

  static double darkerMaxL(double r, double lighterL) {
    final lighterY = Hsluv.lToY(lighterL);
    final maxY = (20 * lighterY - r + 1) / (20 * r);
    return Hsluv.yToL(maxY);
  }
}
