import 'dart:math' as math;

import 'geometry.dart';

///    Human-friendly HSL conversion utility class.
///    The math for most of this module was taken from:
/// * http://www.easyrgb.com
/// * http://www.brucelindbloom.com
/// * Wikipedia
///    All numbers below taken from math/bounds.wxm wxMaxima file. We use 17
///    digits of decimal precision to export the numbers, effectively exporting
///    them as double precision IEEE 754 floats.
///    "If an IEEE 754 double precision is converted to a decimal string with at
///    least 17 significant digits and then converted back to double, then the
///    final number must match the original"
///    Source: https://en.wikipedia.org/wiki/Double-precision_floating-point_format
///    =======
class Hsluv {
  static const m = [
    [3.240969941904521, -1.537383177570093, -0.498610760293],
    [-0.96924363628087, 1.87596750150772, 0.041555057407175],
    [0.055630079696993, -0.20397695888897, 1.056971514242878]
  ];

  static const minv = [
    [0.41239079926595, 0.35758433938387, 0.18048078840183],
    [0.21263900587151, 0.71516867876775, 0.072192315360733],
    [0.019330818715591, 0.11919477979462, 0.95053215224966]
  ];

  static const double refY = 1.0;

  static const double refU = 0.19783000664283;
  static const double refV = 0.46831999493879;

  // CIE LUV constants
  static const double kappa = 903.2962962;
  static const double epsilon = 0.0088564516;

  static const String hexChars = "0123456789abcdef";

  /// For a given lightness, return a list of 6 lines in slope-intercept
  /// form that represent the bounds in CIELUV, stepping over which will
  /// push a value out of the RGB gamut
  static List<Line> getBounds(double L) {
    List<Line> result = [];

    double sub1 = math.pow(L + 16, 3) / 1560896;
    double sub2 = sub1 > epsilon ? sub1 : L / kappa;

    for (int c = 0; c < 3; c++) {
      double m1 = m[c][0];
      double m2 = m[c][1];
      double m3 = m[c][2];

      for (int t = 0; t < 2; t++) {
        double top1 = (284517 * m1 - 94839 * m3) * sub2;
        double top2 = (838422 * m3 + 769860 * m2 + 731718 * m1) * L * sub2 -
            769860 * t * L;
        double bottom = (632260 * m3 - 126452 * m2) * sub2 + 126452 * t;

        result.add(Line(
          slope: top1 / bottom,
          intercept: top2 / bottom,
        ));
      }
    }

    return result;
  }

  /// For given lightness, returns the maximum chroma. Keeping the chroma value
  /// below this number will ensure that for any hue, the color is within the RGB
  /// gamut.
  static double maxSafeChromaForL(double L) {
    List<Line> bounds = getBounds(L);
    double min = double.infinity;

    for (Line bound in bounds) {
      double length = Geometry.distanceLineFromOrigin(bound);
      min = math.min(min, length);
    }

    return min;
  }

  static double maxChromaForLH(double L, double H) {
    double hrad = H / 360 * math.pi * 2;
    List<Line> bounds = getBounds(L);
    double min = double.infinity;

    for (Line bound in bounds) {
      double length = Geometry.lengthOfRayUntilIntersect(hrad, bound);
      if (length >= 0) {
        min = math.min(min, length);
      }
    }

    return min;
  }

  static double dotProduct(List<double> a, List<double> b) {
    double sum = 0;

    for (int i = 0; i < a.length; i += 1) {
      sum += a[i] * b[i];
    }

    return sum;
  }

  // Used for rgb conversions
  static double fromLinear(double c) {
    if (c <= 0.0031308) {
      return 12.92 * c;
    } else {
      return 1.055 * math.pow(c, 1 / 2.4) - 0.055;
    }
  }

  static double toLinear(double c) {
    if (c > 0.04045) {
      return math.pow((c + 0.055) / (1 + 0.055), 2.4) as double;
    } else {
      return c / 12.92;
    }
  }

  /// XYZ coordinates are ranging in [0;1] and RGB coordinates in [0;1] range.
  /// @param tuple An array containing the color's X,Y and Z values.
  /// @return An array containing the resulting color's red, green and blue.
  static List<double> xyzToRgb(List<double> tuple) {
    return [
      fromLinear(dotProduct(m[0], tuple)),
      fromLinear(dotProduct(m[1], tuple)),
      fromLinear(dotProduct(m[2], tuple))
    ];
  }

  /// RGB coordinates are ranging in [0;1] and XYZ coordinates in [0;1].
  /// @param tuple An array containing the color's R,G,B values.
  /// @return An array containing the resulting color's XYZ coordinates.
  static List<double> rgbToXyz(List<double> tuple) {
    List<double> rgbl = [
      toLinear(tuple[0]),
      toLinear(tuple[1]),
      toLinear(tuple[2])
    ];

    return [
      dotProduct(minv[0], rgbl),
      dotProduct(minv[1], rgbl),
      dotProduct(minv[2], rgbl)
    ];
  }

  /// http://en.wikipedia.org/wiki/CIELUV
  /// In these formulas, Yn refers to the reference white point. We are usin g
  /// illuminant D65, so Yn (see refY in Maxima file) equals 1. The formula is
  /// simplified accordingly.
  static double yToL(double Y) {
    if (Y <= epsilon) {
      return (Y / refY) * kappa;
    } else {
      return 116 * math.pow(Y / refY, 1.0 / 3.0) - 16;
    }
  }

  static double lToY(double L) {
    if (L <= 8) {
      return refY * L / kappa;
    } else {
      return refY * math.pow((L + 16) / 116, 3);
    }
  }

  /// XYZ coordinates are ranging in [0;1].
  /// @param tuple An array containing the color's X,Y,Z values.
  /// @return An array containing the resulting color's LUV coordinates.
  static List<double> xyzToLuv(List<double> tuple) {
    double X = tuple[0];
    double Y = tuple[1];
    double Z = tuple[2];

    // This divider fix avoids a crash on Python (divide by zero except.)
    double divider = (X + (15 * Y) + (3 * Z));
    double varU = 4 * X;
    double varV = 9 * Y;

    if (divider != 0) {
      varU /= divider;
      varV /= divider;
    } else {
      varU = double.nan;
      varV = double.nan;
    }

    double L = yToL(Y);

    if (L == 0) {
      return [0, 0, 0];
    }

    double U = 13 * L * (varU - refU);
    double V = 13 * L * (varV - refV);

    return [L, U, V];
  }

  /// XYZ coordinates are ranging in [0;1].
  /// @param tuple An array containing the color's L,U,V values.
  /// @return An array containing the resulting color's XYZ coordinates.
  static List<double> luvToXyz(List<double> tuple) {
    double L = tuple[0];
    double U = tuple[1];
    double V = tuple[2];

    if (L == 0) {
      return [0, 0, 0];
    }

    double varU = U / (13 * L) + refU;
    double varV = V / (13 * L) + refV;

    double Y = lToY(L);
    double X = 0 - (9 * Y * varU) / ((varU - 4) * varV - varU * varV);
    double Z = (9 * Y - (15 * varV * Y) - (varV * X)) / (3 * varV);

    return [X, Y, Z];
  }

  /// @param tuple An array containing the color's L,U,V values.
  /// @return An array containing the resulting color's LCH coordinates.
  static List<double> luvToLch(List<double> tuple) {
    double L = tuple[0];
    double U = tuple[1];
    double V = tuple[2];

    double C = math.sqrt(U * U + V * V);
    double H;

    // Greys: disambiguate hue
    if (C < 0.00000001) {
      H = 0;
    } else {
      double hRad = math.atan2(V, U);
      H = (hRad * 180.0) / math.pi;

      if (H < 0) {
        H = 360 + H;
      }
    }

    return [L, C, H];
  }

  /// @param tuple An array containing the color's L,C,H values.
  /// @return An array containing the resulting color's LUV coordinates.
  static List<double> lchToLuv(List<double> tuple) {
    double L = tuple[0];
    double C = tuple[1];
    double H = tuple[2];

    double hRad = H / 360.0 * 2 * math.pi;
    double U = math.cos(hRad) * C;
    double V = math.sin(hRad) * C;

    return [L, U, V];
  }

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100].
  /// @param tuple An array containing the color's H,S,L values in HSLuv color space.
  /// @return An array containing the resulting color's LCH coordinates.
  static List<double> hsluvToLch(List<double> tuple) {
    double H = tuple[0];
    double S = tuple[1];
    double L = tuple[2];

    // White and black: disambiguate chroma
    if (L > 99.9999999) {
      return [100, 0, H];
    }

    if (L < 0.00000001) {
      return [0, 0, H];
    }

    double max = maxChromaForLH(L, H);
    double C = max / 100 * S;

    return [L, C, H];
  }

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100].
  /// @param tuple An array containing the color's LCH values.
  /// @return An array containing the resulting color's HSL coordinates in HSLuv color space.
  static List<double> lchToHsluv(List<double> tuple) {
    double L = tuple[0];
    double C = tuple[1];
    double H = tuple[2];

    // White and black: disambiguate chroma
    if (L > 99.9999999) {
      return [H, 0, 100];
    }

    if (L < 0.00000001) {
      return [H, 0, 0];
    }

    double max = maxChromaForLH(L, H);
    double S = C / max * 100;

    return [H, S, L];
  }

  /// HSLuv values are in [0;360], [0;100] and [0;100].
  /// @param tuple An array containing the color's H,S,L values in HPLuv (pastel variant) color space.
  /// @return An array containing the resulting color's LCH coordinates.
  static List<double> hpluvToLch(List<double> tuple) {
    double H = tuple[0];
    double S = tuple[1];
    double L = tuple[2];

    if (L > 99.9999999) {
      return [100, 0, H];
    }

    if (L < 0.00000001) {
      return [0, 0, H];
    }

    double max = maxSafeChromaForL(L);
    double C = max / 100 * S;

    return [L, C, H];
  }

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100].
  /// @param tuple An array containing the color's LCH values.
  /// @return An array containing the resulting color's HSL coordinates in HPLuv (pastel variant) color space.
  static List<double> lchToHpluv(List<double> tuple) {
    double L = tuple[0];
    double C = tuple[1];
    double H = tuple[2];

    // White and black: disambiguate saturation
    if (L > 99.9999999) {
      return [H, 0, 100];
    }

    if (L < 0.00000001) {
      return [H, 0, 0];
    }

    double max = maxSafeChromaForL(L);
    double S = C / max * 100;

    return [H, S, L];
  }

  /// RGB values are ranging in [0;1].
  /// @param tuple An array containing the color's RGB values.
  /// @return A string containing a `#RRGGBB` representation of given color.
  static String rgbToHex(List<double> tuple) {
    String h = "#";

    for (int i = 0; i < 3; i += 1) {
      double chan = tuple[i];
      var c = (chan * 255).round();
      var digit2 = c % 16;
      var digit1 = ((c - digit2) ~/ 16);
      h += hexChars[digit1] + hexChars[digit2];
    }

    return h;
  }

  /// RGB values are ranging in [0;1].
  /// @param hex A `#RRGGBB` representation of a color.
  /// @return An array containing the color's RGB values.
  static List<double> hexToRgb(String hex) {
    hex = hex.toLowerCase();
    List<double> ret = [];
    for (var i = 0; i < 3; i += 1) {
      var digit1 = hexChars.indexOf(hex[i * 2 + 1]);
      var digit2 = hexChars.indexOf(hex[i * 2 + 2]);
      var n = digit1 * 16 + digit2;
      ret.add(n / 255.0);
    }
    return ret;
  }

  /// RGB values are ranging in [0;1].
  /// @param tuple An array containing the color's LCH values.
  /// @return An array containing the resulting color's RGB coordinates.
  static List<double> lchToRgb(List<double> tuple) {
    return xyzToRgb(luvToXyz(lchToLuv(tuple)));
  }

  /// RGB values are ranging in [0;1].
  /// @param tuple An array containing the color's RGB values.
  /// @return An array containing the resulting color's LCH coordinates.
  static List<double> rgbToLch(List<double> tuple) {
    return luvToLch(xyzToLuv(rgbToXyz(tuple)));
  }

  // RGB <--> HPLuv

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100] and RGB in [0;1].
  /// @param tuple An array containing the color's HSL values in HSLuv color space.
  /// @return An array containing the resulting color's RGB coordinates.
  static List<double> hsluvToRgb(List<double> tuple) {
    return lchToRgb(hsluvToLch(tuple));
  }

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100] and RGB in [0;1].
  /// @param tuple An array containing the color's RGB coordinates.
  /// @return An array containing the resulting color's HSL coordinates in HSLuv color space.
  static List<double> rgbToHsluv(List<double> tuple) {
    return lchToHsluv(rgbToLch(tuple));
  }

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100] and RGB in [0;1].
  /// @param tuple An array containing the color's HSL values in HPLuv (pastel variant) color space.
  /// @return An array containing the resulting color's RGB coordinates.
  static List<double> hpluvToRgb(List<double> tuple) {
    return lchToRgb(hpluvToLch(tuple));
  }

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100] and RGB in [0;1].
  /// @param tuple An array containing the color's RGB coordinates.
  /// @return An array containing the resulting color's HSL coordinates in HPLuv (pastel variant) color space.
  static List<double> rgbToHpluv(List<double> tuple) {
    return lchToHpluv(rgbToLch(tuple));
  }

  // Hex

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100] and RGB in [0;1].
  /// @param tuple An array containing the color's HSL values in HSLuv color space.
  /// @return A string containing a `#RRGGBB` representation of given color.
  ///*/
  static String hsluvToHex(List<double> tuple) {
    return rgbToHex(hsluvToRgb(tuple));
  }

  static String hpluvToHex(List<double> tuple) {
    return rgbToHex(hpluvToRgb(tuple));
  }

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100] and RGB in [0;1].
  /// @param tuple An array containing the color's HSL values in HPLuv (pastel variant) color space.
  /// @return An array containing the color's HSL values in HSLuv color space.
  ///*/
  static List<double> hexToHsluv(String s) {
    return rgbToHsluv(hexToRgb(s));
  }

  /// HSLuv values are ranging in [0;360], [0;100] and [0;100] and RGB in [0;1].
  /// @param hex A `#RRGGBB` representation of a color.
  /// @return An array containing the color's HSL values in HPLuv (pastel variant) color space.
  ///*/
  static List<double> hexToHpluv(String s) {
    return rgbToHpluv(hexToRgb(s));
  }
}
