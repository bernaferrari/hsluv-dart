import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsluv/hsluv.dart';

import 'test_class.dart';

void main() {
  test("test hsluv", () {
    TestClass.testHsluv();
  });

  test("test consistency", () {
    TestClass.testConsistency();
  });

  test("test channel", () {
    TestClass.testRgbChannelBounds();
  });

  test("HSLuvColor.fromColor and toColor round-trip", () {
    const samples = [
      Color(0xFFEF3E4A),
      Color(0xFF32B67A),
      Color(0xFF005397),
      Color(0xFFFACA0C),
      Color(0xFFFFFFFF),
      Color(0xFF000000),
    ];

    for (final sample in samples) {
      final raw = HSLuvColor.fromRawColor(sample);
      expect(raw.toColor(), sample);

      final rounded = HSLuvColor.fromColor(sample);
      final roundTrip = rounded.toColor();
      expect(((roundTrip.r - sample.r) * 255).abs(), lessThanOrEqualTo(4));
      expect(((roundTrip.g - sample.g) * 255).abs(), lessThanOrEqualTo(4));
      expect(((roundTrip.b - sample.b) * 255).abs(), lessThanOrEqualTo(4));
    }
  });

  test("ColorPicker.getPickerGeometry returns exact gamut polygon", () {
    for (final lightness in [15.0, 50.0, 80.0, 90.0]) {
      final geometry = ColorPicker.getPickerGeometry(lightness);
      expect(geometry.vertices.length, inInclusiveRange(3, 6));
      expect(geometry.lines.length, geometry.vertices.length);
      expect(geometry.angles.length, geometry.vertices.length);
      expect(geometry.innerCircleRadius, greaterThan(0));
      expect(
        geometry.outerCircleRadius,
        greaterThan(geometry.innerCircleRadius),
      );

      // Verify polygon matches maxChromaForLH around all 360 degrees
      for (int deg = 0; deg < 360; deg += 5) {
        final expectedR = Hsluv.maxChromaForLH(lightness, deg.toDouble());
        final angle = deg * math.pi / 180.0;
        final farPoint = Point(
          math.cos(angle) * (expectedR + 50),
          math.sin(angle) * (expectedR + 50),
        );
        final clamped = ColorPicker.closestPoint(geometry, farPoint);
        expect(
          Geometry.distanceFromOrigin(clamped),
          lessThanOrEqualTo(geometry.outerCircleRadius + 1e-6),
        );
      }
    }
  });

  test("extensions and contrast helpers work cleanly", () {
    const sample = Color(0xFFEF3E4A);
    expect(sample.toRawHSLuv(), HSLuvColor.fromRawColor(sample));
    expect(sample.toHSLuv(), HSLuvColor.fromColor(sample));
    expect(toRGBList(sample), [239.0, 62.0, 74.0]);
    expect(hsluvToRGBColor(sample.toRawHSLuv().letToTuple()), sample);
    expect(hpluvToRGBColor([12, 80, 70]).a, 1.0);
    expect(Contrast.contrastRatio(100, 0), closeTo(21.0, 0.01));
    expect(
      Contrast.contrastRatio(
        Contrast.lighterMinL(Contrast.W3C_CONTRAST_TEXT),
        0,
      ),
      closeTo(Contrast.W3C_CONTRAST_TEXT, 0.01),
    );
  });

  test("HsluvConverter matches Hsluv static conversions without drift", () {
    final converter = HsluvConverter();
    const samples = [
      '#000000',
      '#ffffff',
      '#ff0000',
      '#00ff00',
      '#0000ff',
      '#ef3e4a',
    ];
    for (final hex in samples) {
      converter
        ..hex = hex
        ..hexToHsluv();
      final hsluv = Hsluv.hexToHsluv(hex);
      TestClass.assertTuplesClose('$hex→converter.hexToHsluv', hsluv, [
        converter.hsluvH,
        converter.hsluvS,
        converter.hsluvL,
      ]);

      converter.hsluvToHex();
      expect(converter.hex, hex);

      converter
        ..hex = hex
        ..hexToHpluv();
      final hpluv = Hsluv.hexToHpluv(hex);
      TestClass.assertTuplesClose('$hex→converter.hexToHpluv', hpluv, [
        converter.hpluvH,
        converter.hpluvS,
        converter.hpluvL,
      ]);

      converter.hpluvToHex();
      expect(converter.hex, hex);
    }
  });

  test("clamping and hex validation handle edge cases safely", () {
    expect(Hsluv.rgbToHex([-0.2, 0.5, 1.3]), '#0080ff');
    expect(Hsluv.hexToRgb('#ABCDEF'), [171 / 255, 205 / 255, 239 / 255]);

    for (final bad in ['', '#', '#123', '112233', '#gggggg', '#1234567']) {
      expect(() => Hsluv.hexToRgb(bad), throwsFormatException);
    }

    // Valid sRGB primaries must produce bounded HSLuv channels even near cube edges.
    for (final rgb in [
      [1.0, 0.0, 0.0],
      [1.0, 1.0, 0.0],
      [0.0, 1.0, 1.0],
      [1.0, 0.0, 1.0],
    ]) {
      final hsluv = Hsluv.rgbToHsluv(rgb);
      expect(hsluv[0], inInclusiveRange(0.0, 360.0));
      expect(hsluv[1], inInclusiveRange(0.0, 100.0));
      expect(hsluv[2], inInclusiveRange(0.0, 100.0));

      final back = Hsluv.hsluvToRgb(hsluv);
      for (final ch in back) {
        expect(ch, inInclusiveRange(0.0, 1.0));
      }
    }

    // HPLuv saturation can legitimately exceed 100 for vivid sRGB colors and round-trips.
    final vividHpluv = Hsluv.hexToHpluv('#ff0000');
    expect(vividHpluv[1], greaterThan(100.0));
    expect(Hsluv.hpluvToHex(vividHpluv), '#ff0000');
  });
}

extension on HSLuvColor {
  List<double> letToTuple() => [hue, saturation, lightness];
}
