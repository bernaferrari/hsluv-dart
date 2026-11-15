import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:hsluv/contrast.dart';
import 'package:hsluv/hsluvcolor.dart';
import 'package:material_ui/material_ui.dart';

/// Standard WCAG 2.1 contrast ratio between [a] and [b] in [1.0 .. 21.0].
double wcagContrastRatio(Color a, Color b) {
  final lumA = a.computeLuminance();
  final lumB = b.computeLuminance();
  final lighter = math.max(lumA, lumB);
  final darker = math.min(lumA, lumB);
  return (lighter + 0.05) / (darker + 0.05);
}

String wcagLevelLabel(double ratio, {bool largeText = false}) {
  if (largeText) {
    if (ratio >= 4.5) return 'AAA';
    if (ratio >= 3.0) return 'AA';
    return 'FAIL';
  }
  if (ratio >= 7.0) return 'AAA';
  if (ratio >= 4.5) return 'AA';
  if (ratio >= 3.0) return 'AA+';
  return 'FAIL';
}

/// Returns crisp foreground text color (near-black or near-white) with optimal contrast.
Color contrastingTextColor(Color bg) {
  const dark = Color(0xFF0B0F19);
  const light = Color(0xFFF8FAFC);
  return wcagContrastRatio(bg, dark) >= wcagContrastRatio(bg, light)
      ? dark
      : light;
}

/// Computes APCA-W3 perceptual contrast (Lc in roughly -108 .. +106).
double apcaContrast(Color text, Color background) {
  double linearize(double c) => math.pow(c.clamp(0.0, 1.0), 2.4).toDouble();
  double yFor(Color c) {
    final y = 0.2126729 * linearize(c.r) +
        0.7151522 * linearize(c.g) +
        0.0721750 * linearize(c.b);
    const blkThrs = 0.022;
    const blkClmp = 1.414;
    return y > blkThrs ? y : y + math.pow(blkThrs - y, blkClmp);
  }

  final yTxt = yFor(text);
  final yBg = yFor(background);
  if ((yBg - yTxt).abs() < 0.0005) return 0.0;

  const normBg = 0.56;
  const normTxt = 0.57;
  const revBg = 0.65;
  const revTxt = 0.62;
  const scaleBoW = 1.14;
  const scaleWoB = 1.14;
  const loClip = 0.1;
  const loConOffset = 0.027;

  if (yBg > yTxt) {
    final sapc =
        (math.pow(yBg, normBg) - math.pow(yTxt, normTxt)) * scaleBoW;
    if (sapc < loClip) return 0.0;
    return (sapc - loConOffset) * 100.0;
  } else {
    final sapc =
        (math.pow(yBg, revBg) - math.pow(yTxt, revTxt)) * scaleWoB;
    if (sapc > -loClip) return 0.0;
    return (sapc + loConOffset) * 100.0;
  }
}

/// Solves for the nearest [HSLuvColor] lightness that achieves [targetRatio]
/// against [background] while preserving hue and saturation.
HSLuvColor? solveHsluvForContrast(
  HSLuvColor source,
  Color background,
  double targetRatio,
) {
  final bgLuv = HSLuvColor.fromRawColor(background);

  // Use Contrast helper bounds as starting hints, then refine against true sRGB color.
  HSLuvColor? searchDarker() {
    if (wcagContrastRatio(
          source.withLightness(0).toColor(),
          background,
        ) <
        targetRatio) {
      return null;
    }
    var low = 0.0;
    var high = math.min(source.lightness, bgLuv.lightness);
    if (wcagContrastRatio(source.withLightness(high).toColor(), background) >=
        targetRatio) {
      high = source.lightness;
    }
    // Check if even at L=source.lightness it passes
    if (wcagContrastRatio(source.toColor(), background) >= targetRatio) {
      return source;
    }
    // Binary search largest L in [0, bgLuv.lightness] that reaches targetRatio
    low = 0.0;
    high = bgLuv.lightness;
    for (int i = 0; i < 24; i++) {
      final mid = (low + high) * 0.5;
      final candidate = source.withLightness(mid).toColor();
      if (wcagContrastRatio(candidate, background) >= targetRatio) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return source.withLightness(low);
  }

  HSLuvColor? searchLighter() {
    if (wcagContrastRatio(
          source.withLightness(100).toColor(),
          background,
        ) <
        targetRatio) {
      return null;
    }
    if (wcagContrastRatio(source.toColor(), background) >= targetRatio) {
      return source;
    }
    var low = math.max(bgLuv.lightness, Contrast.lighterMinL(targetRatio) * 0.0);
    low = bgLuv.lightness;
    var high = 100.0;
    for (int i = 0; i < 24; i++) {
      final mid = (low + high) * 0.5;
      final candidate = source.withLightness(mid).toColor();
      if (wcagContrastRatio(candidate, background) >= targetRatio) {
        high = mid;
      } else {
        low = mid;
      }
    }
    return source.withLightness(high);
  }

  final darker = searchDarker();
  final lighter = searchLighter();

  if (darker == null) return lighter;
  if (lighter == null) return darker;

  final diffDark = (source.lightness - darker.lightness).abs();
  final diffLight = (lighter.lightness - source.lightness).abs();
  return diffDark <= diffLight ? darker : lighter;
}

/// Color Vision Deficiency simulation types.
enum CvdType {
  normal('Normal Vision', '100% full trichromatic spectrum'),
  protanopia('Protanopia', 'Red-blind (missing L-cones · ~1% males)'),
  deuteranopia('Deuteranopia', 'Green-blind (missing M-cones · ~1% males)'),
  tritanopia('Tritanopia', 'Blue-blind (missing S-cones · <0.1%)'),
  protanomaly('Protanomaly', 'Red-weak (anomalous L-cones · ~1% males)'),
  deuteranomaly('Deuteranomaly', 'Green-weak (anomalous M-cones · ~6% males)'),
  tritanomaly('Tritanomaly', 'Blue-weak (anomalous S-cones · ~0.01%)'),
  achromatopsia('Achromatopsia', 'Total monochromacy (~0.003%)');

  const CvdType(this.label, this.description);

  final String label;
  final String description;

  Color simulate(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);

    List<int> applyMatrix(List<double> m) {
      return [
        (r * m[0] + g * m[1] + b * m[2]).round().clamp(0, 255),
        (r * m[3] + g * m[4] + b * m[5]).round().clamp(0, 255),
        (r * m[6] + g * m[7] + b * m[8]).round().clamp(0, 255),
      ];
    }

    final rgb = switch (this) {
      CvdType.normal => [r, g, b],
      CvdType.protanopia => applyMatrix(const [
          0.567, 0.433, 0.0,
          0.558, 0.442, 0.0,
          0.0, 0.242, 0.758,
        ]),
      CvdType.deuteranopia => applyMatrix(const [
          0.625, 0.375, 0.0,
          0.7, 0.3, 0.0,
          0.0, 0.3, 0.7,
        ]),
      CvdType.tritanopia => applyMatrix(const [
          0.95, 0.05, 0.0,
          0.0, 0.433, 0.567,
          0.0, 0.475, 0.525,
        ]),
      CvdType.protanomaly => applyMatrix(const [
          0.817, 0.183, 0.0,
          0.333, 0.667, 0.0,
          0.0, 0.125, 0.875,
        ]),
      CvdType.deuteranomaly => applyMatrix(const [
          0.8, 0.2, 0.0,
          0.258, 0.742, 0.0,
          0.0, 0.142, 0.858,
        ]),
      CvdType.tritanomaly => applyMatrix(const [
          0.967, 0.033, 0.0,
          0.0, 0.733, 0.267,
          0.0, 0.183, 0.817,
        ]),
      CvdType.achromatopsia => applyMatrix(const [
          0.299, 0.587, 0.114,
          0.299, 0.587, 0.114,
          0.299, 0.587, 0.114,
        ]),
    };

    return Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
  }
}

/// Cached lookup against `assets/colornames.json`.
class ColorNameLookup {
  ColorNameLookup._();

  static List<({String name, int r, int g, int b})>? _entries;
  static Future<void>? _loading;

  static Future<void> ensureLoaded() {
    if (_entries != null) return Future.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/colornames.json');
      final decoded = json.decode(raw) as List<dynamic>;
      _entries = [
        for (final item in decoded)
          if (item is Map<String, dynamic>)
            () {
              final hex = (item['hex'] as String).replaceFirst('#', '');
              final val = int.parse(hex, radix: 16);
              return (
                name: item['name'] as String,
                r: (val >> 16) & 0xFF,
                g: (val >> 8) & 0xFF,
                b: val & 0xFF,
              );
            }(),
      ];
    } catch (_) {
      _entries = const [];
    }
  }

  static String? nearestNameSync(Color color) {
    final entries = _entries;
    if (entries == null || entries.isEmpty) return null;

    final cr = (color.r * 255.0).round().clamp(0, 255);
    final cg = (color.g * 255.0).round().clamp(0, 255);
    final cb = (color.b * 255.0).round().clamp(0, 255);

    var bestDist = 1 << 30;
    String? bestName;

    for (final entry in entries) {
      // Weighted perceptual RGB distance (redmean approximation) for fast exact lookup.
      final dr = cr - entry.r;
      final dg = cg - entry.g;
      final db = cb - entry.b;
      final rMean = (cr + entry.r) >> 1;
      final dist = (((512 + rMean) * dr * dr) >> 8) +
          4 * dg * dg +
          (((767 - rMean) * db * db) >> 8);
      if (dist == 0) return entry.name;
      if (dist < bestDist) {
        bestDist = dist;
        bestName = entry.name;
      }
    }
    return bestName;
  }
}
