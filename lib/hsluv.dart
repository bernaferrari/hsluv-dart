import 'dart:math' as math;

import 'geometry.dart';

export 'color_picker.dart';
export 'contrast.dart';
export 'extensions.dart';
export 'geometry.dart';
export 'hsluvcolor.dart';

/// Reusable, non-allocating converter for HSLuv, HPLuv, CIELUV, CIE LCh, CIE
/// XYZ, sRGB, and hex color conversions.
///
/// Mutates scalar fields in place so tight conversion loops avoid per-color
/// `List` and `Line` heap allocations. For convenience wrappers that accept and
/// return `List<double>`, use [Hsluv].
class HsluvConverter {
  // sRGB / hex
  String hex = '#000000';
  double rgbR = 0.0;
  double rgbG = 0.0;
  double rgbB = 0.0;

  // CIE XYZ
  double xyzX = 0.0;
  double xyzY = 0.0;
  double xyzZ = 0.0;

  // CIE LUV
  double luvL = 0.0;
  double luvU = 0.0;
  double luvV = 0.0;

  // CIE LUV LCh
  double lchL = 0.0;
  double lchC = 0.0;
  double lchH = 0.0;

  // HSLuv
  double hsluvH = 0.0;
  double hsluvS = 0.0;
  double hsluvL = 0.0;

  // HPLuv
  double hpluvH = 0.0;
  double hpluvS = 0.0;
  double hpluvL = 0.0;

  // 6 gamut bounding lines in slope-intercept form: R < 0, R > 1, G < 0, G > 1, B < 0, B > 1
  double r0s = 0.0;
  double r0i = 0.0;
  double r1s = 0.0;
  double r1i = 0.0;

  double g0s = 0.0;
  double g0i = 0.0;
  double g1s = 0.0;
  double g1i = 0.0;

  double b0s = 0.0;
  double b0i = 0.0;
  double b1s = 0.0;
  double b1i = 0.0;

  /// Computes the 6 CIELUV sRGB gamut bounding lines for lightness [l] in
  /// `0..100`, storing their slopes and intercepts on this converter.
  void calculateBoundingLines(double l) {
    final l16 = l + 16;
    final sub1 = (l16 * l16 * l16) / 1560896;
    final sub2 = sub1 > Hsluv.epsilon ? sub1 : l / Hsluv.kappa;

    const mr = Hsluv._m0;
    final s1r = sub2 * (284517 * mr[0] - 94839 * mr[2]);
    final s2r = sub2 * (838422 * mr[2] + 769860 * mr[1] + 731718 * mr[0]);
    final s3r = sub2 * (632260 * mr[2] - 126452 * mr[1]);
    r0s = s1r / s3r;
    r0i = s2r * l / s3r;
    r1s = s1r / (s3r + 126452);
    r1i = (s2r - 769860) * l / (s3r + 126452);

    const mg = Hsluv._m1;
    final s1g = sub2 * (284517 * mg[0] - 94839 * mg[2]);
    final s2g = sub2 * (838422 * mg[2] + 769860 * mg[1] + 731718 * mg[0]);
    final s3g = sub2 * (632260 * mg[2] - 126452 * mg[1]);
    g0s = s1g / s3g;
    g0i = s2g * l / s3g;
    g1s = s1g / (s3g + 126452);
    g1i = (s2g - 769860) * l / (s3g + 126452);

    const mb = Hsluv._m2;
    final s1b = sub2 * (284517 * mb[0] - 94839 * mb[2]);
    final s2b = sub2 * (838422 * mb[2] + 769860 * mb[1] + 731718 * mb[0]);
    final s3b = sub2 * (632260 * mb[2] - 126452 * mb[1]);
    b0s = s1b / s3b;
    b0i = s2b * l / s3b;
    b1s = s1b / (s3b + 126452);
    b1i = (s2b - 769860) * l / (s3b + 126452);
  }

  static double _distanceFromOrigin(double slope, double intercept) {
    return intercept.abs() / math.sqrt(slope * slope + 1);
  }

  static double _distanceFromOriginAngle(
    double slope,
    double intercept,
    double angle,
  ) {
    final length = intercept / (math.sin(angle) - slope * math.cos(angle));
    return length >= 0 ? length : double.infinity;
  }

  static double _min6(
    double a,
    double b,
    double c,
    double d,
    double e,
    double f,
  ) {
    return math.min(math.min(math.min(a, b), math.min(c, d)), math.min(e, f));
  }

  /// Returns the maximum pastel chroma representable at the lightness most
  /// recently passed to [calculateBoundingLines].
  double calcMaxChromaHpluv() {
    return _min6(
      _distanceFromOrigin(r0s, r0i),
      _distanceFromOrigin(r1s, r1i),
      _distanceFromOrigin(g0s, g0i),
      _distanceFromOrigin(g1s, g1i),
      _distanceFromOrigin(b0s, b0i),
      _distanceFromOrigin(b1s, b1i),
    );
  }

  /// Returns the maximum chroma for hue [h] (in degrees) at the lightness
  /// most recently passed to [calculateBoundingLines].
  double calcMaxChromaHsluv(double h) {
    final hRad = h / 180.0 * math.pi;
    return _min6(
      _distanceFromOriginAngle(r0s, r0i, hRad),
      _distanceFromOriginAngle(r1s, r1i, hRad),
      _distanceFromOriginAngle(g0s, g0i, hRad),
      _distanceFromOriginAngle(g1s, g1i, hRad),
      _distanceFromOriginAngle(b0s, b0i, hRad),
      _distanceFromOriginAngle(b1s, b1i, hRad),
    );
  }

  /// Converts [xyzX], [xyzY], [xyzZ] to linear/gamma sRGB in [rgbR], [rgbG],
  /// [rgbB].
  void xyzToRgb() {
    const m0 = Hsluv._m0;
    const m1 = Hsluv._m1;
    const m2 = Hsluv._m2;
    rgbR = Hsluv.fromLinear(m0[0] * xyzX + m0[1] * xyzY + m0[2] * xyzZ);
    rgbG = Hsluv.fromLinear(m1[0] * xyzX + m1[1] * xyzY + m1[2] * xyzZ);
    rgbB = Hsluv.fromLinear(m2[0] * xyzX + m2[1] * xyzY + m2[2] * xyzZ);
  }

  /// Converts [rgbR], [rgbG], [rgbB] to CIE XYZ in [xyzX], [xyzY], [xyzZ].
  void rgbToXyz() {
    final lr = Hsluv.toLinear(rgbR);
    final lg = Hsluv.toLinear(rgbG);
    final lb = Hsluv.toLinear(rgbB);
    const minv0 = Hsluv._minv0;
    const minv1 = Hsluv._minv1;
    const minv2 = Hsluv._minv2;
    xyzX = minv0[0] * lr + minv0[1] * lg + minv0[2] * lb;
    xyzY = minv1[0] * lr + minv1[1] * lg + minv1[2] * lb;
    xyzZ = minv2[0] * lr + minv2[1] * lg + minv2[2] * lb;
  }

  /// Converts [xyzX], [xyzY], [xyzZ] to CIELUV in [luvL], [luvU], [luvV].
  void xyzToLuv() {
    // This divider guard avoids divide-by-zero at pure black.
    final divider = xyzX + 15 * xyzY + 3 * xyzZ;
    var varU = 4 * xyzX;
    var varV = 9 * xyzY;

    if (divider != 0) {
      varU /= divider;
      varV /= divider;
    } else {
      varU = double.nan;
      varV = double.nan;
    }

    luvL = Hsluv.yToL(xyzY);
    if (luvL == 0) {
      luvU = 0;
      luvV = 0;
    } else {
      luvU = 13 * luvL * (varU - Hsluv.refU);
      luvV = 13 * luvL * (varV - Hsluv.refV);
    }
  }

  /// Converts [luvL], [luvU], [luvV] to CIE XYZ in [xyzX], [xyzY], [xyzZ].
  void luvToXyz() {
    if (luvL == 0) {
      xyzX = 0;
      xyzY = 0;
      xyzZ = 0;
      return;
    }

    final varU = luvU / (13 * luvL) + Hsluv.refU;
    final varV = luvV / (13 * luvL) + Hsluv.refV;

    xyzY = Hsluv.lToY(luvL);
    xyzX = 0 - (9 * xyzY * varU) / ((varU - 4) * varV - varU * varV);
    xyzZ = (9 * xyzY - 15 * varV * xyzY - varV * xyzX) / (3 * varV);
  }

  /// Converts [luvL], [luvU], [luvV] to CIE LCh in [lchL], [lchC], [lchH].
  void luvToLch() {
    lchL = luvL;
    lchC = math.sqrt(luvU * luvU + luvV * luvV);

    // Greys: disambiguate hue.
    if (lchC < 0.00000001) {
      lchH = 0;
    } else {
      final hRad = math.atan2(luvV, luvU);
      lchH = (hRad * 180.0) / math.pi;
      if (lchH < 0) {
        lchH = 360 + lchH;
      }
    }
  }

  /// Converts [lchL], [lchC], [lchH] to CIELUV in [luvL], [luvU], [luvV].
  void lchToLuv() {
    final hRad = lchH / 180.0 * math.pi;
    luvL = lchL;
    luvU = math.cos(hRad) * lchC;
    luvV = math.sin(hRad) * lchC;
  }

  /// Converts [hsluvH], [hsluvS], [hsluvL] to CIE LCh in [lchL], [lchC],
  /// [lchH].
  void hsluvToLch() {
    // White and black: disambiguate chroma.
    if (hsluvL > 99.9999999) {
      lchL = 100;
      lchC = 0;
    } else if (hsluvL < 0.00000001) {
      lchL = 0;
      lchC = 0;
    } else {
      lchL = hsluvL;
      calculateBoundingLines(hsluvL);
      final max = calcMaxChromaHsluv(hsluvH);
      lchC = max / 100 * hsluvS;
    }
    lchH = hsluvH;
  }

  /// Converts [lchL], [lchC], [lchH] to HSLuv in [hsluvH], [hsluvS], [hsluvL].
  void lchToHsluv() {
    // White and black: disambiguate chroma.
    if (lchL > 99.9999999) {
      hsluvS = 0;
      hsluvL = 100;
    } else if (lchL < 0.00000001) {
      hsluvS = 0;
      hsluvL = 0;
    } else {
      calculateBoundingLines(lchL);
      final max = calcMaxChromaHsluv(lchH);
      hsluvS = lchC / max * 100;
      hsluvL = lchL;
    }
    hsluvH = lchH;
  }

  /// Converts [hpluvH], [hpluvS], [hpluvL] to CIE LCh in [lchL], [lchC],
  /// [lchH].
  void hpluvToLch() {
    if (hpluvL > 99.9999999) {
      lchL = 100;
      lchC = 0;
    } else if (hpluvL < 0.00000001) {
      lchL = 0;
      lchC = 0;
    } else {
      lchL = hpluvL;
      calculateBoundingLines(hpluvL);
      final max = calcMaxChromaHpluv();
      lchC = max / 100 * hpluvS;
    }
    lchH = hpluvH;
  }

  /// Converts [lchL], [lchC], [lchH] to HPLuv in [hpluvH], [hpluvS], [hpluvL].
  void lchToHpluv() {
    // White and black: disambiguate saturation.
    if (lchL > 99.9999999) {
      hpluvS = 0;
      hpluvL = 100;
    } else if (lchL < 0.00000001) {
      hpluvS = 0;
      hpluvL = 0;
    } else {
      calculateBoundingLines(lchL);
      final max = calcMaxChromaHpluv();
      hpluvS = lchC / max * 100;
      hpluvL = lchL;
    }
    hpluvH = lchH;
  }

  static String _channelToHex(double channel) {
    final c = (channel * 255).round().clamp(0, 255);
    return Hsluv.hexChars[c >> 4] + Hsluv.hexChars[c & 0xF];
  }

  static double _parseHexByte(String hex, int offset) {
    final digit1 = Hsluv.hexChars.indexOf(hex[offset]);
    final digit2 = Hsluv.hexChars.indexOf(hex[offset + 1]);
    if (digit1 < 0 || digit2 < 0) {
      throw FormatException('Invalid hex color: $hex');
    }
    return (digit1 * 16 + digit2) / 255.0;
  }

  /// Formats [rgbR], [rgbG], [rgbB] (clamped to `0..1`) as `#rrggbb` in [hex].
  void rgbToHex() {
    hex = '#${_channelToHex(rgbR)}${_channelToHex(rgbG)}${_channelToHex(rgbB)}';
  }

  /// Parses `#RRGGBB` in [hex] into [rgbR], [rgbG], [rgbB].
  ///
  /// Throws a [FormatException] if [hex] is not a valid 7-character `#RRGGBB`
  /// string.
  void hexToRgb() {
    if (hex.length != 7 || hex.codeUnitAt(0) != 0x23) {
      throw FormatException('Expected #RRGGBB hex string, got: $hex');
    }
    final normalized = hex.toLowerCase();
    rgbR = _parseHexByte(normalized, 1);
    rgbG = _parseHexByte(normalized, 3);
    rgbB = _parseHexByte(normalized, 5);
  }

  /// Converts [lchL], [lchC], [lchH] to sRGB in [rgbR], [rgbG], [rgbB].
  void lchToRgb() {
    lchToLuv();
    luvToXyz();
    xyzToRgb();
  }

  /// Converts [rgbR], [rgbG], [rgbB] to CIE LCh in [lchL], [lchC], [lchH].
  void rgbToLch() {
    rgbToXyz();
    xyzToLuv();
    luvToLch();
  }

  void _clampRgb() {
    rgbR = rgbR.clamp(0.0, 1.0);
    rgbG = rgbG.clamp(0.0, 1.0);
    rgbB = rgbB.clamp(0.0, 1.0);
  }

  /// Converts [hsluvH], [hsluvS], [hsluvL] to clamped sRGB (`0..1`) in
  /// [rgbR], [rgbG], [rgbB].
  void hsluvToRgb() {
    hsluvToLch();
    lchToRgb();
    _clampRgb();
  }

  /// Converts [rgbR], [rgbG], [rgbB] to clamped HSLuv (`H` in `0..360`,
  /// `S` and `L` in `0..100`) in [hsluvH], [hsluvS], [hsluvL].
  void rgbToHsluv() {
    rgbToLch();
    lchToHsluv();
    hsluvH = hsluvH.clamp(0.0, 360.0);
    hsluvS = hsluvS.clamp(0.0, 100.0);
    hsluvL = hsluvL.clamp(0.0, 100.0);
  }

  /// Converts [hpluvH], [hpluvS], [hpluvL] to clamped sRGB (`0..1`) in
  /// [rgbR], [rgbG], [rgbB].
  void hpluvToRgb() {
    hpluvToLch();
    lchToRgb();
    _clampRgb();
  }

  /// Converts [rgbR], [rgbG], [rgbB] to HPLuv in [hpluvH], [hpluvS], [hpluvL].
  ///
  /// `hpluvH` is clamped to `0..360` and `hpluvL` to `0..100`. Because HPLuv
  /// is an inscribed subset of sRGB, [hpluvS] can exceed `100` for saturated
  /// sRGB inputs; it is left unclamped so round-trips remain invertible.
  void rgbToHpluv() {
    rgbToLch();
    lchToHpluv();
    hpluvH = hpluvH.clamp(0.0, 360.0);
    hpluvL = hpluvL.clamp(0.0, 100.0);
  }

  /// Converts [hsluvH], [hsluvS], [hsluvL] to `#rrggbb` in [hex].
  void hsluvToHex() {
    hsluvToRgb();
    rgbToHex();
  }

  /// Converts [hpluvH], [hpluvS], [hpluvL] to `#rrggbb` in [hex].
  void hpluvToHex() {
    hpluvToRgb();
    rgbToHex();
  }

  /// Parses [hex] (`#RRGGBB`) and writes clamped HSLuv to [hsluvH],
  /// [hsluvS], [hsluvL].
  void hexToHsluv() {
    hexToRgb();
    rgbToHsluv();
  }

  /// Parses [hex] (`#RRGGBB`) and writes HPLuv to [hpluvH], [hpluvS],
  /// [hpluvL].
  void hexToHpluv() {
    hexToRgb();
    rgbToHpluv();
  }
}

/// Human-friendly HSL conversion utility class (HSLuv revision 4).
///
/// The math for most of this module was taken from:
/// * http://www.easyrgb.com
/// * http://www.brucelindbloom.com
/// * Wikipedia
///
/// All numbers below match `math/hsluv.mac` from `hsluv/hsluv`.
/// For allocation-free batch conversions, instantiate [HsluvConverter].
class Hsluv {
  static const _m0 = [3.240969941904521, -1.537383177570093, -0.498610760293];
  static const _m1 = [-0.96924363628087, 1.87596750150772, 0.041555057407175];
  static const _m2 = [0.055630079696993, -0.20397695888897, 1.056971514242878];
  static const m = [_m0, _m1, _m2];

  static const _minv0 = [0.41239079926595, 0.35758433938387, 0.18048078840183];
  static const _minv1 = [0.21263900587151, 0.71516867876775, 0.072192315360733];
  static const _minv2 = [0.019330818715591, 0.11919477979462, 0.95053215224966];
  static const minv = [_minv0, _minv1, _minv2];

  static const double refY = 1.0;

  static const double refU = 0.19783000664283;
  static const double refV = 0.46831999493879;

  // CIE LUV constants
  static const double kappa = 903.2962962;
  static const double epsilon = 0.0088564516;

  static const String hexChars = "0123456789abcdef";

  // Single-isolate scratch converter shared by the synchronous static helpers
  // so formulas live in one place and avoid per-call intermediate allocations.
  static final HsluvConverter _shared = HsluvConverter();

  /// For a given lightness [L], returns the 6 slope-intercept bounding lines in
  /// CIELUV that define the sRGB gamut polygon.
  static List<Line> getBounds(double L) {
    _shared.calculateBoundingLines(L);
    return [
      Line(slope: _shared.r0s, intercept: _shared.r0i),
      Line(slope: _shared.r1s, intercept: _shared.r1i),
      Line(slope: _shared.g0s, intercept: _shared.g0i),
      Line(slope: _shared.g1s, intercept: _shared.g1i),
      Line(slope: _shared.b0s, intercept: _shared.b0i),
      Line(slope: _shared.b1s, intercept: _shared.b1i),
    ];
  }

  /// For a given lightness [L], returns the maximum chroma guaranteed to stay
  /// within the sRGB gamut for every hue (the HPLuv radius).
  static double maxSafeChromaForL(double L) {
    _shared.calculateBoundingLines(L);
    return _shared.calcMaxChromaHpluv();
  }

  /// For lightness [L] and hue [H] (in degrees), returns the maximum sRGB-valid
  /// CIELUV chroma.
  static double maxChromaForLH(double L, double H) {
    _shared.calculateBoundingLines(L);
    return _shared.calcMaxChromaHsluv(H);
  }

  /// Computes the dot product of vectors [a] and [b].
  static double dotProduct(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i += 1) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  /// Converts linear-light RGB channel [c] to gamma-encoded sRGB.
  static double fromLinear(double c) {
    if (c <= 0.0031308) {
      return 12.92 * c;
    } else {
      return 1.055 * math.pow(c, 1 / 2.4) - 0.055;
    }
  }

  /// Converts gamma-encoded sRGB channel [c] to linear-light RGB.
  static double toLinear(double c) {
    if (c > 0.04045) {
      return math.pow((c + 0.055) / (1 + 0.055), 2.4) as double;
    } else {
      return c / 12.92;
    }
  }

  /// Converts relative luminance [Y] (illuminant D65, [refY] = 1) to CIELUV
  /// lightness `L*`.
  static double yToL(double Y) {
    if (Y <= epsilon) {
      return (Y / refY) * kappa;
    } else {
      return 116 * math.pow(Y / refY, 1.0 / 3.0) - 16;
    }
  }

  /// Converts CIELUV lightness [L] (`L*`) to relative luminance `Y`.
  static double lToY(double L) {
    if (L <= 8) {
      return refY * L / kappa;
    } else {
      return refY * math.pow((L + 16) / 116, 3);
    }
  }

  /// Converts CIE XYZ (`X, Y, Z` in `0..1`) [tuple] to sRGB (`R, G, B` in
  /// `0..1`).
  static List<double> xyzToRgb(List<double> tuple) {
    _shared
      ..xyzX = tuple[0]
      ..xyzY = tuple[1]
      ..xyzZ = tuple[2]
      ..xyzToRgb();
    return [_shared.rgbR, _shared.rgbG, _shared.rgbB];
  }

  /// Converts sRGB (`R, G, B` in `0..1`) [tuple] to CIE XYZ (`X, Y, Z` in
  /// `0..1`).
  static List<double> rgbToXyz(List<double> tuple) {
    _shared
      ..rgbR = tuple[0]
      ..rgbG = tuple[1]
      ..rgbB = tuple[2]
      ..rgbToXyz();
    return [_shared.xyzX, _shared.xyzY, _shared.xyzZ];
  }

  /// Converts CIE XYZ [tuple] to CIELUV `[L, U, V]`.
  static List<double> xyzToLuv(List<double> tuple) {
    _shared
      ..xyzX = tuple[0]
      ..xyzY = tuple[1]
      ..xyzZ = tuple[2]
      ..xyzToLuv();
    return [_shared.luvL, _shared.luvU, _shared.luvV];
  }

  /// Converts CIELUV [tuple] to CIE XYZ `[X, Y, Z]`.
  static List<double> luvToXyz(List<double> tuple) {
    _shared
      ..luvL = tuple[0]
      ..luvU = tuple[1]
      ..luvV = tuple[2]
      ..luvToXyz();
    return [_shared.xyzX, _shared.xyzY, _shared.xyzZ];
  }

  /// Converts CIELUV [tuple] to CIE LCh `[L, C, H]`.
  static List<double> luvToLch(List<double> tuple) {
    _shared
      ..luvL = tuple[0]
      ..luvU = tuple[1]
      ..luvV = tuple[2]
      ..luvToLch();
    return [_shared.lchL, _shared.lchC, _shared.lchH];
  }

  /// Converts CIE LCh [tuple] to CIELUV `[L, U, V]`.
  static List<double> lchToLuv(List<double> tuple) {
    _shared
      ..lchL = tuple[0]
      ..lchC = tuple[1]
      ..lchH = tuple[2]
      ..lchToLuv();
    return [_shared.luvL, _shared.luvU, _shared.luvV];
  }

  /// Converts HSLuv (`H` in `0..360`, `S` in `0..100`, `L` in `0..100`) [tuple]
  /// to CIE LCh `[L, C, H]`.
  static List<double> hsluvToLch(List<double> tuple) {
    _shared
      ..hsluvH = tuple[0]
      ..hsluvS = tuple[1]
      ..hsluvL = tuple[2]
      ..hsluvToLch();
    return [_shared.lchL, _shared.lchC, _shared.lchH];
  }

  /// Converts CIE LCh [tuple] to HSLuv `[H, S, L]` (`0..360`, `0..100`,
  /// `0..100`).
  static List<double> lchToHsluv(List<double> tuple) {
    _shared
      ..lchL = tuple[0]
      ..lchC = tuple[1]
      ..lchH = tuple[2]
      ..lchToHsluv();
    return [_shared.hsluvH, _shared.hsluvS, _shared.hsluvL];
  }

  /// Converts HPLuv (`H` in `0..360`, `S` in `0..100`, `L` in `0..100`) [tuple]
  /// to CIE LCh `[L, C, H]`.
  static List<double> hpluvToLch(List<double> tuple) {
    _shared
      ..hpluvH = tuple[0]
      ..hpluvS = tuple[1]
      ..hpluvL = tuple[2]
      ..hpluvToLch();
    return [_shared.lchL, _shared.lchC, _shared.lchH];
  }

  /// Converts CIE LCh [tuple] to HPLuv `[H, S, L]`.
  static List<double> lchToHpluv(List<double> tuple) {
    _shared
      ..lchL = tuple[0]
      ..lchC = tuple[1]
      ..lchH = tuple[2]
      ..lchToHpluv();
    return [_shared.hpluvH, _shared.hpluvS, _shared.hpluvL];
  }

  /// Formats sRGB (`0..1`) [tuple] as a `#rrggbb` hex string, clamping each
  /// channel to `0..255`.
  static String rgbToHex(List<double> tuple) {
    _shared
      ..rgbR = tuple[0]
      ..rgbG = tuple[1]
      ..rgbB = tuple[2]
      ..rgbToHex();
    return _shared.hex;
  }

  /// Parses a `#RRGGBB` [hex] string into normalized sRGB `[R, G, B]` in
  /// `0..1`.
  ///
  /// Throws a [FormatException] if [hex] is not a valid 7-character `#RRGGBB`
  /// string.
  static List<double> hexToRgb(String hex) {
    _shared
      ..hex = hex
      ..hexToRgb();
    return [_shared.rgbR, _shared.rgbG, _shared.rgbB];
  }

  /// Converts CIE LCh [tuple] to sRGB `[R, G, B]`.
  static List<double> lchToRgb(List<double> tuple) {
    _shared
      ..lchL = tuple[0]
      ..lchC = tuple[1]
      ..lchH = tuple[2]
      ..lchToRgb();
    return [_shared.rgbR, _shared.rgbG, _shared.rgbB];
  }

  /// Converts sRGB [tuple] (`0..1`) to CIE LCh `[L, C, H]`.
  static List<double> rgbToLch(List<double> tuple) {
    _shared
      ..rgbR = tuple[0]
      ..rgbG = tuple[1]
      ..rgbB = tuple[2]
      ..rgbToLch();
    return [_shared.lchL, _shared.lchC, _shared.lchH];
  }

  /// Converts HSLuv (`H` in `0..360`, `S` and `L` in `0..100`) [tuple] to
  /// clamped sRGB `[R, G, B]` in `0..1`.
  static List<double> hsluvToRgb(List<double> tuple) {
    _shared
      ..hsluvH = tuple[0]
      ..hsluvS = tuple[1]
      ..hsluvL = tuple[2]
      ..hsluvToRgb();
    return [_shared.rgbR, _shared.rgbG, _shared.rgbB];
  }

  /// Converts sRGB [tuple] (`0..1`) to clamped HSLuv `[H, S, L]` (`0..360`,
  /// `0..100`, `0..100`).
  static List<double> rgbToHsluv(List<double> tuple) {
    _shared
      ..rgbR = tuple[0]
      ..rgbG = tuple[1]
      ..rgbB = tuple[2]
      ..rgbToHsluv();
    return [_shared.hsluvH, _shared.hsluvS, _shared.hsluvL];
  }

  /// Converts HPLuv (`H` in `0..360`, `S` and `L` in `0..100`) [tuple] to
  /// clamped sRGB `[R, G, B]` in `0..1`.
  static List<double> hpluvToRgb(List<double> tuple) {
    _shared
      ..hpluvH = tuple[0]
      ..hpluvS = tuple[1]
      ..hpluvL = tuple[2]
      ..hpluvToRgb();
    return [_shared.rgbR, _shared.rgbG, _shared.rgbB];
  }

  /// Converts sRGB [tuple] (`0..1`) to HPLuv `[H, S, L]`.
  ///
  /// Because HPLuv is a pastel subset of sRGB, `S` can exceed `100` for
  /// saturated sRGB inputs; it is preserved unclamped so round-trips remain
  /// exact.
  static List<double> rgbToHpluv(List<double> tuple) {
    _shared
      ..rgbR = tuple[0]
      ..rgbG = tuple[1]
      ..rgbB = tuple[2]
      ..rgbToHpluv();
    return [_shared.hpluvH, _shared.hpluvS, _shared.hpluvL];
  }

  /// Converts HSLuv (`H` in `0..360`, `S` and `L` in `0..100`) [tuple] to a
  /// `#rrggbb` hex string.
  static String hsluvToHex(List<double> tuple) {
    _shared
      ..hsluvH = tuple[0]
      ..hsluvS = tuple[1]
      ..hsluvL = tuple[2]
      ..hsluvToHex();
    return _shared.hex;
  }

  /// Converts HPLuv (`H` in `0..360`, `S` and `L` in `0..100`) [tuple] to a
  /// `#rrggbb` hex string.
  static String hpluvToHex(List<double> tuple) {
    _shared
      ..hpluvH = tuple[0]
      ..hpluvS = tuple[1]
      ..hpluvL = tuple[2]
      ..hpluvToHex();
    return _shared.hex;
  }

  /// Converts a `#RRGGBB` hex string [s] to HSLuv `[H, S, L]`.
  static List<double> hexToHsluv(String s) {
    _shared
      ..hex = s
      ..hexToHsluv();
    return [_shared.hsluvH, _shared.hsluvS, _shared.hsluvL];
  }

  /// Converts a `#RRGGBB` hex string [s] to HPLuv `[H, S, L]`.
  static List<double> hexToHpluv(String s) {
    _shared
      ..hex = s
      ..hexToHpluv();
    return [_shared.hpluvH, _shared.hpluvS, _shared.hpluvL];
  }
}
