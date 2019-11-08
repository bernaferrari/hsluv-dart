import 'package:flutter_test/flutter_test.dart';
import 'package:hsluv/hsluv.dart';

import 'snapshot.dart';

const MAXDIFF = 0.0000000001;
const MAXRELDIFF = 0.000000001;

class TestClass {
  /// modified from
  /// https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/
  static bool assertAlmostEqualRelativeAndAbs(double a, double b) {
    // Check if the numbers are really close -- needed
    // when comparing numbers near zero.
    double diff = (a - b).abs();
    if (diff <= MAXDIFF) {
      return true;
    }

    a = a.abs();
    b = b.abs();
    double largest = (b > a) ? b : a;

    return diff <= largest * MAXRELDIFF;
  }

  static assertTuplesClose(
      String label, List<double> expected, List<double> actual) {
    bool mismatch = false;
    List<double> deltas = [];

    for (int i = 0; i < expected.length; i += 1) {
      deltas.add((expected[i] - actual[i]).abs());
      if (!assertAlmostEqualRelativeAndAbs(expected[i], actual[i])) {
        mismatch = true;
      }
    }

    if (mismatch) {
      print("MISMATCH " + label);
      print(" expected: ${expected[0]} ${expected[1]} ${expected[2]}");
      print("  actual: ${actual[0]} ${actual[1]} ${actual[2]}");
      print("  deltas: ${deltas[0]} ${deltas[1]} ${expected[2]}");
    }

    expect(mismatch, false);
  }

  static void testConsistency() {
    var samples = Snapshot.generateHexSamples();
    for (String hex in samples) {
      expect(hex, Hsluv.hsluvToHex(Hsluv.hexToHsluv(hex)));
      expect(hex, Hsluv.hpluvToHex(Hsluv.hexToHpluv(hex)));
    }
  }

  static void testRgbChannelBounds() {
    // TODO: Consider clipping RGB channels instead and testing with 0 error tolerance
    for (double r = 0.0; r < 1.0; r += 0.01) {
      for (double g = 0.0; g < 1.0; g += 0.01) {
        for (double b = 0.0; b < 1.0; b += 0.01) {
          var sample = [r, g, b];
          var hsluv = Hsluv.rgbToHsluv(sample);
          var hpluv = Hsluv.rgbToHpluv(sample);
          var rgbHsluv = Hsluv.hsluvToRgb(hsluv);
          var rgbHpluv = Hsluv.hpluvToRgb(hpluv);
          assertTuplesClose('RGB -> HSLuv -> RGB', sample, rgbHsluv);
          assertTuplesClose('RGB -> HPLuv -> RGB', sample, rgbHpluv);
        }
      }
    }
  }

  static void testHsluv() {
    var snapshot = Snapshot.generateSnapshot();
    for (var fieldName in snapshot.keys) {
      var field = snapshot[fieldName];

      var rgbFromHex = Hsluv.hexToRgb(fieldName);
      var xyzFromRgb = Hsluv.rgbToXyz(field["rgb"]);
      var luvFromXyz = Hsluv.xyzToLuv(field["xyz"]);
      var lchFromLuv = Hsluv.luvToLch(field["luv"]);
      var hsluvFromLch = Hsluv.lchToHsluv(field["lch"]);
      var hpluvFromLch = Hsluv.lchToHpluv(field["lch"]);
      var hsluvFromHex = Hsluv.hexToHsluv(fieldName);
      var hpluvFromHex = Hsluv.hexToHpluv(fieldName);

      assertTuplesClose(fieldName + "→" + "hexToRgb", field["rgb"], rgbFromHex);
      assertTuplesClose(fieldName + "→" + "rgbToXyz", field["xyz"], xyzFromRgb);
      assertTuplesClose(fieldName + "→" + "xyzToLuv", field["luv"], luvFromXyz);
      assertTuplesClose(fieldName + "→" + "luvToLch", field["lch"], lchFromLuv);
      assertTuplesClose(
          fieldName + "→" + "lchToHsluv", field["hsluv"], hsluvFromLch);
      assertTuplesClose(
          fieldName + "→" + "lchToHpluv", field["hpluv"], hpluvFromLch);
      assertTuplesClose(
          fieldName + "→" + "hexToHsluv", field["hsluv"], hsluvFromHex);
      assertTuplesClose(
          fieldName + "→" + "hexToHpluv", field["hpluv"], hpluvFromHex);

      // backward functions

      var lchFromHsluv = Hsluv.hsluvToLch(field["hsluv"]);
      var lchFromHpluv = Hsluv.hpluvToLch(field["hpluv"]);
      var luvFromLch = Hsluv.lchToLuv(field["lch"]);
      var xyzFromLuv = Hsluv.luvToXyz(field["luv"]);
      var rgbFromXyz = Hsluv.xyzToRgb(field["xyz"]);
      var hexFromRgb = Hsluv.rgbToHex(field["rgb"]);
      var hexFromHsluv = Hsluv.hsluvToHex(field["hsluv"]);
      var hexFromHpluv = Hsluv.hpluvToHex(field["hpluv"]);

      assertTuplesClose("hsluvToLch", field["lch"], lchFromHsluv);
      assertTuplesClose("hpluvToLch", field["lch"], lchFromHpluv);
      assertTuplesClose("lchToLuv", field["luv"], luvFromLch);
      assertTuplesClose("luvToXyz", field["xyz"], xyzFromLuv);
      assertTuplesClose("xyzToRgb", field["rgb"], rgbFromXyz);
      // toLowerCase because some targets such as lua have hard time parsing hex code with various cases
      expect(fieldName, hexFromRgb.toLowerCase());
      expect(fieldName, hexFromHsluv.toLowerCase());
      expect(fieldName, hexFromHpluv.toLowerCase());
    }
  }
}
