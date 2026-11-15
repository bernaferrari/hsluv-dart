import 'package:flutter_test/flutter_test.dart';
import 'package:hsluv/hsluv.dart';

import 'snapshot.dart';

const maxDiff = 0.0000000001;
const maxRelDiff = 0.000000001;

class TestClass {
  /// modified from
  /// https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/
  static bool assertAlmostEqualRelativeAndAbs(double a, double b) {
    // Check if the numbers are really close -- needed
    // when comparing numbers near zero.
    final double diff = (a - b).abs();
    if (diff <= maxDiff) {
      return true;
    }

    final absA = a.abs();
    final absB = b.abs();
    final double largest = (absB > absA) ? absB : absA;

    return diff <= largest * maxRelDiff;
  }

  static void assertTuplesClose(
      String label, List<double> expected, List<double> actual) {
    bool mismatch = false;
    final List<double> deltas = [];

    for (int i = 0; i < expected.length; i += 1) {
      deltas.add((expected[i] - actual[i]).abs());
      if (!assertAlmostEqualRelativeAndAbs(expected[i], actual[i])) {
        mismatch = true;
      }
    }

    if (mismatch) {
      fail(
        'MISMATCH $label\n'
        ' expected: ${expected[0]} ${expected[1]} ${expected[2]}\n'
        '   actual: ${actual[0]} ${actual[1]} ${actual[2]}\n'
        '   deltas: ${deltas[0]} ${deltas[1]} ${deltas[2]}',
      );
    }

    expect(mismatch, false);
  }

  static void testConsistency() {
    final samples = Snapshot.generateHexSamples();
    for (final String hex in samples) {
      expect(hex, Hsluv.hsluvToHex(Hsluv.hexToHsluv(hex)));
      expect(hex, Hsluv.hpluvToHex(Hsluv.hexToHpluv(hex)));
    }
  }

  static void testRgbChannelBounds() {
    // TODO: Consider clipping RGB channels instead and testing with 0 error tolerance
    for (double r = 0.0; r < 1.0; r += 0.01) {
      for (double g = 0.0; g < 1.0; g += 0.01) {
        for (double b = 0.0; b < 1.0; b += 0.01) {
          final sample = [r, g, b];
          final hsluv = Hsluv.rgbToHsluv(sample);
          final hpluv = Hsluv.rgbToHpluv(sample);
          final rgbHsluv = Hsluv.hsluvToRgb(hsluv);
          final rgbHpluv = Hsluv.hpluvToRgb(hpluv);
          assertTuplesClose('RGB -> HSLuv -> RGB', sample, rgbHsluv);
          assertTuplesClose('RGB -> HPLuv -> RGB', sample, rgbHpluv);
        }
      }
    }
  }

  static void testHsluv() {
    final snapshot = Snapshot.generateSnapshot();
    for (final fieldName in snapshot.keys) {
      final field = snapshot[fieldName]!;

      final rgbFromHex = Hsluv.hexToRgb(fieldName);
      final xyzFromRgb = Hsluv.rgbToXyz(field["rgb"]!);
      final luvFromXyz = Hsluv.xyzToLuv(field["xyz"]!);
      final lchFromLuv = Hsluv.luvToLch(field["luv"]!);
      final hsluvFromLch = Hsluv.lchToHsluv(field["lch"]!);
      final hpluvFromLch = Hsluv.lchToHpluv(field["lch"]!);
      final hsluvFromHex = Hsluv.hexToHsluv(fieldName);
      final hpluvFromHex = Hsluv.hexToHpluv(fieldName);

      assertTuplesClose('$fieldName→hexToRgb', field["rgb"]!, rgbFromHex);
      assertTuplesClose('$fieldName→rgbToXyz', field["xyz"]!, xyzFromRgb);
      assertTuplesClose('$fieldName→xyzToLuv', field["luv"]!, luvFromXyz);
      assertTuplesClose('$fieldName→luvToLch', field["lch"]!, lchFromLuv);
      assertTuplesClose(
          '$fieldName→lchToHsluv', field["hsluv"]!, hsluvFromLch);
      assertTuplesClose(
          '$fieldName→lchToHpluv', field["hpluv"]!, hpluvFromLch);
      assertTuplesClose(
          '$fieldName→hexToHsluv', field["hsluv"]!, hsluvFromHex);
      assertTuplesClose(
          '$fieldName→hexToHpluv', field["hpluv"]!, hpluvFromHex);

      // backward functions

      final lchFromHsluv = Hsluv.hsluvToLch(field["hsluv"]!);
      final lchFromHpluv = Hsluv.hpluvToLch(field["hpluv"]!);
      final luvFromLch = Hsluv.lchToLuv(field["lch"]!);
      final xyzFromLuv = Hsluv.luvToXyz(field["luv"]!);
      final rgbFromXyz = Hsluv.xyzToRgb(field["xyz"]!);
      final hexFromRgb = Hsluv.rgbToHex(field["rgb"]!);
      final hexFromHsluv = Hsluv.hsluvToHex(field["hsluv"]!);
      final hexFromHpluv = Hsluv.hpluvToHex(field["hpluv"]!);

      assertTuplesClose("hsluvToLch", field["lch"]!, lchFromHsluv);
      assertTuplesClose("hpluvToLch", field["lch"]!, lchFromHpluv);
      assertTuplesClose("lchToLuv", field["luv"]!, luvFromLch);
      assertTuplesClose("luvToXyz", field["xyz"]!, xyzFromLuv);
      assertTuplesClose("xyzToRgb", field["rgb"]!, rgbFromXyz);
      // toLowerCase because some targets such as lua have hard time parsing hex code with various cases
      expect(fieldName, hexFromRgb.toLowerCase());
      expect(fieldName, hexFromHsluv.toLowerCase());
      expect(fieldName, hexFromHpluv.toLowerCase());
    }
  }
}
