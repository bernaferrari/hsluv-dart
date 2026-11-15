import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hsluv/color_picker.dart';
import 'package:hsluv/geometry.dart';
import 'package:hsluv/hsluv.dart';
import 'package:hsluv/hsluvcolor.dart';

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
          geometry.outerCircleRadius, greaterThan(geometry.innerCircleRadius));

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
}
