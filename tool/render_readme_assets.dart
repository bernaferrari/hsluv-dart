// Generates the README visual assets for `hsluv`:
//   - assets/logo.png
//   - build/readme_frames/hsluv_vs_hsl_solid/*.png  -> assets/hsluv_vs_hsl_solid.webp
//   - build/readme_frames/hpluv_vs_hsluv_solid/*.png -> assets/hpluv_vs_hsluv_solid.webp
//   - build/readme_frames/hsl_vs_hsluv/*.png        -> assets/hsl_vs_hsluv.webp
//
// Run via `./tool/generate_assets.sh` (downloads fonts into build/readme_fonts;
// requires `flutter`, `curl`, `ffmpeg`, and `img2webp`).
//
// Visual language: a dark "luminance lab". Every colour strip is paired with
// its grayscale twin (the same colours mapped to their L*), and every solid
// has an L* ruler, so uniform lightness is something you can see, not read.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show HSLColor;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsluv/hsluv.dart';

const ui.Color _bg = ui.Color(0xFF101113);
const ui.Color _hairline = ui.Color(0xFF26282D);
const ui.Color _fg = ui.Color(0xFFF1F1EF);
const ui.Color _muted = ui.Color(0xFF8B8E95);
const ui.Color _faint = ui.Color(0xFF4C4F56);

const double _width = 760.0;
const double _dpr = 2.0;
const double _sheetRadius = 22.0;
const double _pad = 28.0;
const int _frames = 150;
const int _ribbonSamples = 180;

// Typography ------------------------------------------------------------------

typedef _Span = (String, ui.TextStyle);

ui.TextStyle _style(
  String family,
  double size,
  double weight,
  ui.Color color, {
  double letterSpacing = 0,
}) {
  return ui.TextStyle(
    fontFamily: family,
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing,
    fontWeight: ui.FontWeight.values[(weight / 100).round() - 1],
    fontVariations: [ui.FontVariation('wght', weight)],
    fontFeatures: const [ui.FontFeature.tabularFigures()],
  );
}

ui.TextStyle _display(double size, {double weight = 700, ui.Color? color}) =>
    _style('Display', size, weight, color ?? _fg, letterSpacing: -size * 0.035);

ui.TextStyle _mono(double size, {ui.Color color = _muted, bool bold = false}) =>
    _style(bold ? 'MonoMedium' : 'Mono', size, bold ? 500 : 400, color);

enum _Anchor { start, center, end }

double _text(
  ui.Canvas canvas,
  List<_Span> spans, {
  required double x,
  required double baseline,
  _Anchor anchor = _Anchor.start,
}) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle());
  for (final (text, style) in spans) {
    builder
      ..pushStyle(style)
      ..addText(text)
      ..pop();
  }
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: 2000));
  final width = paragraph.maxIntrinsicWidth;
  final dx = switch (anchor) {
    _Anchor.start => x,
    _Anchor.center => x - width / 2,
    _Anchor.end => x - width,
  };
  canvas.drawParagraph(
    paragraph,
    ui.Offset(dx, baseline - paragraph.alphabeticBaseline),
  );
  paragraph.dispose();
  return width;
}

String _pad3(double value) => value.round().toString().padLeft(3, '0');

// Colour helpers --------------------------------------------------------------

ui.Color _rgb(List<double> rgb) => ui.Color.from(
  alpha: 1.0,
  red: rgb[0].clamp(0.0, 1.0),
  green: rgb[1].clamp(0.0, 1.0),
  blue: rgb[2].clamp(0.0, 1.0),
);

double _lstar(ui.Color color) => Hsluv.rgbToLch([color.r, color.g, color.b])[0];

ui.Color _grayOf(double lstar) => _rgb(Hsluv.lchToRgb([lstar, 0.0, 0.0]));

ui.Color _hsl(double hue, double saturationPct, double lightnessPct) =>
    HSLColor.fromAHSL(
      1.0,
      hue % 360.0,
      saturationPct / 100.0,
      lightnessPct / 100.0,
    ).toColor();

ui.Color _hsluv(double hue, double saturationPct, double lightnessPct) =>
    _rgb(Hsluv.hsluvToRgb([hue % 360.0, saturationPct, lightnessPct]));

ui.Color _hpluv(double hue, double saturationPct, double lightnessPct) =>
    _rgb(Hsluv.hpluvToRgb([hue % 360.0, saturationPct, lightnessPct]));

List<ui.Color> _sweep(ui.Color Function(double hue) colorAt) => [
  for (var i = 0; i <= _ribbonSamples; i++) colorAt(i * 360.0 / _ribbonSamples),
];

(double, double) _range(Iterable<double> values) =>
    (values.reduce(math.min), values.reduce(math.max));

String _rangeLabel((double, double) range) {
  final (low, high) = range;
  return low.round() == high.round()
      ? '${low.round()}'
      : '${low.round()}–${high.round()}';
}

// Shared chrome ---------------------------------------------------------------

ui.Paint _stroke(ui.Color color, [double width = 1.0]) => ui.Paint()
  ..style = ui.PaintingStyle.stroke
  ..strokeWidth = width
  ..color = color;

void _paintSheet(ui.Canvas canvas, ui.Size size) {
  final sheet = ui.RRect.fromRectAndRadius(
    ui.Offset.zero & size,
    const ui.Radius.circular(_sheetRadius),
  ).deflate(0.5);
  canvas.drawRRect(sheet, ui.Paint()..color = _bg);
  canvas.drawRRect(sheet, _stroke(_hairline));
}

void _divider(ui.Canvas canvas, ui.Offset a, ui.Offset b) =>
    canvas.drawLine(a, b, _stroke(_hairline));

/// A colour strip with its grayscale twin underneath: the same samples mapped
/// to the neutral gray of equal L*. Uniform lightness shows up as a flat twin.
void _paintTwinRibbon(
  ui.Canvas canvas,
  ui.Rect rect,
  List<ui.Color> colors, {
  double twinHeight = 12,
  double radius = 8,
}) {
  final stops = [
    for (var i = 0; i < colors.length; i++) i / (colors.length - 1),
  ];
  final grays = [for (final c in colors) _grayOf(_lstar(c))];
  final colorRect = ui.Rect.fromLTRB(
    rect.left,
    rect.top,
    rect.right,
    rect.bottom - twinHeight,
  );
  final twinRect = ui.Rect.fromLTRB(
    rect.left,
    rect.bottom - twinHeight,
    rect.right,
    rect.bottom,
  );
  final clip = ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(radius));
  canvas.save();
  canvas.clipRRect(clip);
  ui.Shader gradient(List<ui.Color> c) =>
      ui.Gradient.linear(rect.centerLeft, rect.centerRight, c, stops);
  canvas.drawRect(colorRect, ui.Paint()..shader = gradient(colors));
  canvas.drawRect(twinRect, ui.Paint()..shader = gradient(grays));
  canvas.drawLine(
    twinRect.topLeft,
    twinRect.topRight,
    _stroke(_bg.withValues(alpha: 0.9), 1.5),
  );
  canvas.restore();
}

/// Hue axis ticks below a ribbon: 0° … 360°.
void _paintHueTicks(ui.Canvas canvas, ui.Rect ribbon, double baseline) {
  for (var hue = 0; hue <= 360; hue += 60) {
    final x = ribbon.left + ribbon.width * hue / 360;
    canvas.drawLine(
      ui.Offset(x, ribbon.bottom + 3),
      ui.Offset(x, ribbon.bottom + 7),
      _stroke(_faint),
    );
    _text(
      canvas,
      [('$hue°', _mono(9, color: _faint))],
      x: x,
      baseline: baseline,
      anchor: hue == 0
          ? _Anchor.start
          : hue == 360
          ? _Anchor.end
          : _Anchor.center,
    );
  }
}

// 3D solids -------------------------------------------------------------------

class _Camera {
  new({
    required this.yaw,
    required ui.Size size,
    required ui.Offset offset,
    this.radius = 0.56,
    double pitch = 0.50,
  }) : centre = offset + ui.Offset(size.width / 2, size.height / 2),
       scale = math.max(1.0, math.min(size.width / 1.35, size.height / 1.55)),
       _sinPitch = math.sin(pitch),
       _cosPitch = math.cos(pitch);

  final double yaw;
  final ui.Offset centre;
  final double scale;
  final double radius;
  final double _sinPitch;
  final double _cosPitch;

  static double _height(double lightnessPct) => lightnessPct / 100 - 0.5;

  (double, double, double) project(
    double hue,
    double distance,
    double lightnessPct,
  ) {
    final angle = hue * math.pi / 180 - yaw;
    final across = distance * math.cos(angle);
    final towards = distance * math.sin(angle);
    final up = _height(lightnessPct);
    return (
      centre.dx + scale * across,
      centre.dy + scale * (towards * _sinPitch - up * _cosPitch),
      towards * _cosPitch + up * _sinPitch,
    );
  }

  double axisY(double lightnessPct) => project(0, 0, lightnessPct).$2;
}

class _SolidMesh {
  new({
    required this.columns,
    required double Function(double lightness, double hue) reachOf,
    required ui.Color Function(double hue, double lightness) colorOf,
  }) : reach = Float32List((rows + 1) * columns),
       colors = Int32List((rows + 1) * columns) {
    for (var row = 0; row <= rows; row++) {
      final lightness = lightnessOf(row);
      for (var column = 0; column < columns; column++) {
        final hue = hueOf(column);
        final at = row * columns + column;
        reach[at] = (lightness <= 0.01 || lightness >= 99.99)
            ? 0.0
            : reachOf(lightness, hue);
        colors[at] = colorOf(hue, lightness).toARGB32();
      }
    }
  }

  static const int rows = 40;

  final int columns;
  final Float32List reach;
  final Int32List colors;

  double hueOf(int column) => column * 360.0 / columns;
  static double lightnessOf(int row) => row * 100.0 / rows;
}

class _Slice {
  new({
    required this.columns,
    required this.lightness,
    required double Function(double hue) reachOf,
    required ui.Color Function(double hue, double saturationPct) colorOf,
  }) : reach = Float32List(columns),
       colors = Int32List((rings + 1) * columns) {
    for (var column = 0; column < columns; column++) {
      final hue = column * 360.0 / columns;
      reach[column] = reachOf(hue);
      for (var ring = 0; ring <= rings; ring++) {
        colors[ring * columns + column] = colorOf(
          hue,
          ring * 100.0 / rings,
        ).toARGB32();
      }
    }
  }

  static const int rings = 6;

  final int columns;
  final double lightness;
  final Float32List reach;
  final Int32List colors;
}

Uint16List _quadIndices(Iterable<int> faces, int columns) {
  final list = faces.toList();
  final indices = Uint16List(list.length * 6);
  var cursor = 0;
  for (final face in list) {
    final ring = face ~/ columns;
    final column = face % columns;
    final next = (column + 1) % columns;
    final a = ring * columns + column;
    final b = ring * columns + next;
    final c = (ring + 1) * columns + next;
    final d = (ring + 1) * columns + column;
    indices
      ..[cursor++] = a
      ..[cursor++] = b
      ..[cursor++] = c
      ..[cursor++] = a
      ..[cursor++] = c
      ..[cursor++] = d;
  }
  return indices;
}

void _paintSolid(
  ui.Canvas canvas,
  _Camera camera,
  _SolidMesh mesh,
  _Slice slice, {
  List<double>? ghostSliceReach,
  bool drawCageRibs = false,
}) {
  final columns = mesh.columns;
  const cageRingEvery = 5;
  const cageRibEvery = 6;
  final rowsBelow = (slice.lightness / (100 / _SolidMesh.rows)).ceil();

  if (rowsBelow > 0) {
    final ringCount = rowsBelow + 1;
    final positions = Float32List(ringCount * columns * 2);
    final colors = Int32List(ringCount * columns);
    final nearness = Float32List(ringCount * columns);
    final topColors = _Slice.rings * columns;

    for (var ring = 0; ring < ringCount; ring++) {
      final isCut = ring == rowsBelow;
      final lightness = isCut ? slice.lightness : _SolidMesh.lightnessOf(ring);
      for (var column = 0; column < columns; column++) {
        final at = ring * columns + column;
        final (x, y, near) = camera.project(
          mesh.hueOf(column),
          (isCut ? slice.reach[column] : mesh.reach[at]) * camera.radius,
          lightness,
        );
        positions[at * 2] = x;
        positions[at * 2 + 1] = y;
        nearness[at] = near;
        colors[at] = isCut ? slice.colors[topColors + column] : mesh.colors[at];
      }
    }

    final faces = List<int>.generate(rowsBelow * columns, (face) => face);
    final faceNearness = Float32List(faces.length);
    for (final face in faces) {
      final ring = face ~/ columns;
      final column = face % columns;
      final next = (column + 1) % columns;
      faceNearness[face] =
          nearness[ring * columns + column] +
          nearness[ring * columns + next] +
          nearness[(ring + 1) * columns + column] +
          nearness[(ring + 1) * columns + next];
    }
    faces.sort((a, b) => faceNearness[a].compareTo(faceNearness[b]));

    canvas.drawVertices(
      ui.Vertices.raw(
        ui.VertexMode.triangles,
        positions,
        colors: colors,
        indices: _quadIndices(faces, columns),
      ),
      ui.BlendMode.dst,
      ui.Paint(),
    );
  }

  const rings = _Slice.rings;
  final slicePos = Float32List((rings + 1) * columns * 2);
  final edge = ui.Path();
  for (var ring = 0; ring <= rings; ring++) {
    for (var column = 0; column < columns; column++) {
      final at = ring * columns + column;
      final (x, y, _) = camera.project(
        mesh.hueOf(column),
        slice.reach[column] * camera.radius * ring / rings,
        slice.lightness,
      );
      slicePos[at * 2] = x;
      slicePos[at * 2 + 1] = y;
      if (ring != rings) continue;
      if (column == 0) {
        edge.moveTo(x, y);
      } else {
        edge.lineTo(x, y);
      }
    }
  }
  edge.close();

  canvas.drawVertices(
    ui.Vertices.raw(
      ui.VertexMode.triangles,
      slicePos,
      colors: slice.colors,
      indices: _quadIndices(
        List<int>.generate(rings * columns, (face) => face),
        columns,
      ),
    ),
    ui.BlendMode.dst,
    ui.Paint(),
  );

  if (ghostSliceReach != null) {
    final outer = ui.Path();
    for (var column = 0; column < columns; column++) {
      final (x, y, _) = camera.project(
        mesh.hueOf(column),
        ghostSliceReach[column] * camera.radius,
        slice.lightness,
      );
      if (column == 0) {
        outer.moveTo(x, y);
      } else {
        outer.lineTo(x, y);
      }
    }
    outer.close();
    _paintDashed(canvas, outer, _stroke(_fg.withValues(alpha: 0.55)));
  }

  canvas.drawPath(edge, _stroke(_fg.withValues(alpha: 0.9), 1.5));

  final cage = ui.Path();
  ui.Offset corner(int row, int column) {
    final (x, y, _) = camera.project(
      mesh.hueOf(column),
      mesh.reach[row * columns + column] * camera.radius,
      _SolidMesh.lightnessOf(row),
    );
    return ui.Offset(x, y);
  }

  for (var row = rowsBelow; row <= _SolidMesh.rows; row++) {
    final isTop = row == _SolidMesh.rows;
    if (row % cageRingEvery != 0 && !isTop) continue;
    if (_SolidMesh.lightnessOf(row) <= slice.lightness) continue;
    cage.addPolygon([
      for (var column = 0; column < columns; column++) corner(row, column),
    ], true);
  }
  if (drawCageRibs) {
    for (var column = 0; column < columns; column += cageRibEvery) {
      final (x, y, _) = camera.project(
        mesh.hueOf(column),
        slice.reach[column] * camera.radius,
        slice.lightness,
      );
      cage.addPolygon([
        ui.Offset(x, y),
        for (var row = rowsBelow; row <= _SolidMesh.rows; row++)
          if (_SolidMesh.lightnessOf(row) > slice.lightness)
            corner(row, column),
      ], false);
    }
  }
  canvas.drawPath(
    cage,
    _stroke(_fg.withValues(alpha: 0.14))..strokeJoin = ui.StrokeJoin.round,
  );
}

void _paintDashed(ui.Canvas canvas, ui.Path path, ui.Paint paint) {
  const dash = 4.0;
  const gap = 3.0;
  for (final metric in path.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += dash + gap) {
      canvas.drawPath(metric.extractPath(d, d + dash), paint);
    }
  }
}

/// L* ruler aligned with the solid's vertical axis, marking the current cut.
void _paintRuler(ui.Canvas canvas, _Camera camera, double x, double lightness) {
  final top = camera.axisY(100);
  final bottom = camera.axisY(0);
  canvas.drawLine(ui.Offset(x, top), ui.Offset(x, bottom), _stroke(_faint));
  for (var l = 0; l <= 100; l += 10) {
    final y = camera.axisY(l.toDouble());
    final major = l % 50 == 0;
    canvas.drawLine(
      ui.Offset(x, y),
      ui.Offset(x - (major ? 7 : 4), y),
      _stroke(_faint),
    );
    if (major) {
      _text(
        canvas,
        [('$l', _mono(9, color: _faint))],
        x: x - 11,
        baseline: y + 3,
        anchor: _Anchor.end,
      );
    }
  }
  final y = camera.axisY(lightness);
  final marker = ui.Path()
    ..moveTo(x + 1, y)
    ..lineTo(x + 7, y - 4)
    ..lineTo(x + 7, y + 4)
    ..close();
  canvas.drawPath(marker, ui.Paint()..color = _fg);
  canvas.drawLine(ui.Offset(x - 7, y), ui.Offset(x, y), _stroke(_fg, 1.5));
}

typedef _SolidPanel = ({
  String name,
  String note,
  _SolidMesh mesh,
  _Slice slice,
  List<ui.Color> cut,
  String readout,
  List<double>? ghost,
  bool ribs,
});

const ui.Size _solidSize = ui.Size(_width, 452);

void _paintSolidComparison(
  ui.Canvas canvas, {
  required double yaw,
  required double lightness,
  required List<_SolidPanel> panels,
  required String readoutName,
  double cameraRadius = 0.56,
  double pitch = 0.50,
}) {
  _paintSheet(canvas, _solidSize);
  const columnWidth = _width / 2;
  _divider(
    canvas,
    const ui.Offset(columnWidth, 0.5),
    const ui.Offset(columnWidth, 451.5),
  );

  for (var i = 0; i < panels.length; i++) {
    final panel = panels[i];
    final left = i * columnWidth;

    _text(canvas, [(panel.name, _display(22))], x: left + _pad, baseline: 46);
    _text(canvas, [(panel.note, _mono(10.5))], x: left + _pad, baseline: 66);
    _text(
      canvas,
      [
        ('L ', _mono(10.5)),
        (lightness.round().toString().padLeft(2), _mono(10.5, color: _fg)),
      ],
      x: left + columnWidth - _pad,
      baseline: 46,
      anchor: _Anchor.end,
    );

    final camera = _Camera(
      yaw: yaw,
      size: const ui.Size(columnWidth - 84, 262),
      offset: ui.Offset(left + 62, 82),
      radius: cameraRadius,
      pitch: pitch,
    );
    _paintSolid(
      canvas,
      camera,
      panel.mesh,
      panel.slice,
      ghostSliceReach: panel.ghost,
      drawCageRibs: panel.ribs,
    );
    _paintRuler(canvas, camera, left + _pad + 14, lightness);

    final ribbon = ui.Rect.fromLTWH(
      left + _pad,
      388,
      columnWidth - _pad * 2,
      34,
    );
    _text(
      canvas,
      [('same colors in grayscale', _mono(10))],
      x: ribbon.left,
      baseline: ribbon.top - 10,
    );
    _text(
      canvas,
      [
        ('$readoutName ', _mono(10)),
        (panel.readout, _mono(10, color: _fg, bold: true)),
      ],
      x: ribbon.right,
      baseline: ribbon.top - 10,
      anchor: _Anchor.end,
    );
    _paintTwinRibbon(canvas, ribbon, panel.cut, twinHeight: 12, radius: 7);
  }
}

// Assets ----------------------------------------------------------------------

const ui.Size _heroSize = ui.Size(_width, 272);

void _paintHero(ui.Canvas canvas) {
  _paintSheet(canvas, _heroSize);

  _text(
    canvas,
    [('hsluv  ·  rev. 4  ·  dart & flutter', _mono(10.5))],
    x: 40,
    baseline: 56,
  );
  _text(canvas, [('HSLuv', _display(72, weight: 800))], x: 36, baseline: 134);
  _text(
    canvas,
    [('Hue moves. Lightness stays.', _display(18, weight: 600))],
    x: 40,
    baseline: 174,
  );
  _text(
    canvas,
    [
      (
        'A human-friendly HSL for Dart & Flutter.',
        _display(14.5, weight: 500, color: _muted),
      ),
    ],
    x: 40,
    baseline: 198,
  );
  _text(
    canvas,
    [
      (r'$ ', _mono(11, color: _faint)),
      ('dart pub add hsluv', _mono(11, color: _fg)),
    ],
    x: 40,
    baseline: 234,
  );

  const ribbonLeft = 382.0;
  const ribbonWidth = 340.0;
  final hsl = _sweep((h) => _hsl(h, 100, 50));
  final hsluv = _sweep((h) => _hsluv(h, 100, 60));
  final rows = [
    ('HSL', 's 100  l 50', hsl, 60.0),
    ('HSLuv', 's 100  l 60', hsluv, 146.0),
  ];
  for (final (name, params, colors, top) in rows) {
    final ribbon = ui.Rect.fromLTWH(ribbonLeft, top, ribbonWidth, 48);
    _text(
      canvas,
      [('$name  ', _mono(10.5, color: _fg, bold: true)), (params, _mono(10.5))],
      x: ribbon.left,
      baseline: ribbon.top - 10,
    );
    _text(
      canvas,
      [
        ('L* ', _mono(10.5)),
        (_rangeLabel(_range(colors.map(_lstar))), _mono(10.5, color: _fg)),
      ],
      x: ribbon.right,
      baseline: ribbon.top - 10,
      anchor: _Anchor.end,
    );
    _paintTwinRibbon(canvas, ribbon, colors, twinHeight: 16);
  }
  _paintHueTicks(
    canvas,
    const ui.Rect.fromLTWH(ribbonLeft, 146, ribbonWidth, 48),
    218,
  );
}

void _paintHslVsHsluvSolid(
  ui.Canvas canvas,
  double t, {
  required _SolidMesh hsluvMesh,
  required _SolidMesh hslMesh,
}) {
  final yaw = 0.65 + 2 * math.pi * t;
  final lightness = 62.5 + 22.5 * math.cos(2 * math.pi * t);
  final hsluvCut = _sweep((h) => _hsluv(h, 100, lightness));
  final hslCut = _sweep((h) => _hsl(h, 100, lightness));

  _paintSolidComparison(
    canvas,
    yaw: yaw,
    lightness: lightness,
    readoutName: 'L*',
    panels: [
      (
        name: 'HSLuv',
        note: 'one lightness per height',
        mesh: hsluvMesh,
        slice: _Slice(
          columns: hsluvMesh.columns,
          lightness: lightness,
          reachOf: (_) => 1.0,
          colorOf: (h, s) => _hsluv(h, s, lightness),
        ),
        cut: hsluvCut,
        readout: _rangeLabel(_range(hsluvCut.map(_lstar))),
        ghost: null,
        ribs: true,
      ),
      (
        name: 'HSL',
        note: 'yellow glows, blue sinks',
        mesh: hslMesh,
        slice: _Slice(
          columns: hslMesh.columns,
          lightness: lightness,
          reachOf: (_) => 1.0,
          colorOf: (h, s) => _hsl(h, s, lightness),
        ),
        cut: hslCut,
        readout: _rangeLabel(_range(hslCut.map(_lstar))),
        ghost: null,
        ribs: true,
      ),
    ],
  );
}

void _paintHpluvVsHsluvSolid(
  ui.Canvas canvas,
  double t, {
  required _SolidMesh hsluvMesh,
  required _SolidMesh hpluvMesh,
  required double maxChroma,
}) {
  final yaw = 0.65 + 2 * math.pi * t;
  final lightness = 62.5 + 22.5 * math.cos(2 * math.pi * t);
  final outerReach = [
    for (var c = 0; c < hsluvMesh.columns; c++)
      Hsluv.maxChromaForLH(lightness, hsluvMesh.hueOf(c)) / maxChroma,
  ];
  final safeChroma = Hsluv.maxSafeChromaForL(lightness);
  final hsluvChroma = [
    for (var i = 0; i <= _ribbonSamples; i++)
      Hsluv.maxChromaForLH(lightness, i * 360.0 / _ribbonSamples),
  ];

  _paintSolidComparison(
    canvas,
    yaw: yaw,
    lightness: lightness,
    readoutName: 'C*',
    cameraRadius: 0.68,
    pitch: 0.48,
    panels: [
      (
        name: 'HSLuv',
        note: 'saturation reaches the sRGB edge',
        mesh: hsluvMesh,
        slice: _Slice(
          columns: hsluvMesh.columns,
          lightness: lightness,
          reachOf: (h) => Hsluv.maxChromaForLH(lightness, h) / maxChroma,
          colorOf: (h, s) => _hsluv(h, s, lightness),
        ),
        cut: _sweep((h) => _hsluv(h, 100, lightness)),
        readout: _rangeLabel(_range(hsluvChroma)),
        ghost: null,
        ribs: false,
      ),
      (
        name: 'HPLuv',
        note: 'equal chroma for every hue',
        mesh: hpluvMesh,
        slice: _Slice(
          columns: hpluvMesh.columns,
          lightness: lightness,
          reachOf: (_) => safeChroma / maxChroma,
          colorOf: (h, s) => _hpluv(h, s, lightness),
        ),
        cut: _sweep((h) => _hpluv(h, 100, lightness)),
        readout: '${safeChroma.round()}',
        ghost: outerReach,
        ribs: false,
      ),
    ],
  );
}

const ui.Size _waveSize = ui.Size(_width, 420);

void _paintWaveform(
  ui.Canvas canvas,
  double t, {
  required List<ui.Color> hslSweep,
  required List<ui.Color> hsluvSweep,
}) {
  _paintSheet(canvas, _waveSize);
  _divider(
    canvas,
    const ui.Offset(0.5, 210),
    const ui.Offset(_width - 0.5, 210),
  );

  final hue = t * 360.0;
  final rows = [
    (
      name: 'HSL',
      note: 'lightness jumps with hue',
      color: _hsl(hue, 88, 62),
      sweep: hslSweep,
      top: 0.0,
    ),
    (
      name: 'HSLuv',
      note: 'lightness holds steady',
      color: _hsluv(hue, 88, 62),
      sweep: hsluvSweep,
      top: 210.0,
    ),
  ];

  for (final row in rows) {
    final top = row.top;
    final lstar = _lstar(row.color);

    // Specimen: the colour and its gray, as one chip.
    final chip = ui.Rect.fromLTWH(_pad, top + 30, 104, 150);
    canvas.save();
    canvas.clipRRect(
      ui.RRect.fromRectAndRadius(chip, const ui.Radius.circular(14)),
    );
    canvas.drawRect(
      ui.Rect.fromLTRB(chip.left, chip.top, chip.right, chip.bottom - 42),
      ui.Paint()..color = row.color,
    );
    canvas.drawRect(
      ui.Rect.fromLTRB(chip.left, chip.bottom - 42, chip.right, chip.bottom),
      ui.Paint()..color = _grayOf(lstar),
    );
    canvas.restore();
    _text(
      canvas,
      [
        (
          'L* ',
          _mono(
            10.5,
            color: lstar > 55
                ? _bg.withValues(alpha: 0.6)
                : _fg.withValues(alpha: 0.7),
          ),
        ),
        (
          lstar.round().toString(),
          _mono(10.5, color: lstar > 55 ? _bg : _fg, bold: true),
        ),
      ],
      x: chip.left + 12,
      baseline: chip.bottom - 16,
    );

    const contentLeft = _pad + 104 + 28;
    const contentRight = _width - _pad;
    final nameWidth = _text(
      canvas,
      [(row.name, _display(20))],
      x: contentLeft,
      baseline: top + 48,
    );
    _text(
      canvas,
      [('s 88  l 62  ·  ${row.note}', _mono(10.5))],
      x: contentLeft + nameWidth + 12,
      baseline: top + 47,
    );
    _text(
      canvas,
      [('hue ', _mono(10.5)), ('${_pad3(hue)}°', _mono(10.5, color: _fg))],
      x: contentRight,
      baseline: top + 47,
      anchor: _Anchor.end,
    );

    final ribbon = ui.Rect.fromLTRB(
      contentLeft,
      top + 64,
      contentRight,
      top + 98,
    );
    _paintTwinRibbon(canvas, ribbon, row.sweep, twinHeight: 12, radius: 7);

    final plot = ui.Rect.fromLTRB(
      contentLeft,
      top + 112,
      contentRight,
      top + 180,
    );
    for (final level in [0.0, 50.0, 100.0]) {
      final y = plot.bottom - plot.height * level / 100;
      canvas.drawLine(
        ui.Offset(plot.left, y),
        ui.Offset(plot.right, y),
        _stroke(_hairline),
      );
    }
    _text(
      canvas,
      [('L*', _mono(9, color: _faint))],
      x: plot.left + 2,
      baseline: plot.top - 3,
    );

    final curve = ui.Path();
    for (var i = 0; i <= _ribbonSamples; i++) {
      final x = plot.left + plot.width * i / _ribbonSamples;
      final y = plot.bottom - plot.height * _lstar(row.sweep[i]) / 100;
      if (i == 0) {
        curve.moveTo(x, y);
      } else {
        curve.lineTo(x, y);
      }
    }
    canvas.drawPath(
      curve,
      _stroke(_fg, 2)
        ..strokeJoin = ui.StrokeJoin.round
        ..shader = ui.Gradient.linear(
          plot.centerLeft,
          plot.centerRight,
          row.sweep,
          [for (var i = 0; i <= _ribbonSamples; i++) i / _ribbonSamples],
        ),
    );

    final x = ribbon.left + ribbon.width * hue / 360;
    final y = plot.bottom - plot.height * lstar / 100;
    canvas.drawLine(
      ui.Offset(x, ribbon.bottom + 2),
      ui.Offset(x, plot.bottom),
      _stroke(_fg.withValues(alpha: 0.22)),
    );
    final ribbonMid = ui.Offset(x, ribbon.top + (ribbon.height - 12) / 2);
    canvas.drawCircle(ribbonMid, 8, _stroke(_fg, 2));
    canvas.drawCircle(ui.Offset(x, y), 5.5, ui.Paint()..color = _bg);
    canvas.drawCircle(ui.Offset(x, y), 4, ui.Paint()..color = _fg);
  }
}

// Rendering -------------------------------------------------------------------

Future<void> _render(
  ui.Size size,
  String path,
  void Function(ui.Canvas canvas) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..scale(_dpr, _dpr);
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    (size.width * _dpr).round(),
    (size.height * _dpr).round(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
}

Future<void> _renderFrames(
  ui.Size size,
  String name,
  void Function(ui.Canvas canvas, double t) paint,
) async {
  for (var frame = 0; frame < _frames; frame++) {
    final file = frame.toString().padLeft(4, '0');
    await _render(
      size,
      'build/readme_frames/$name/frame_$file.png',
      (canvas) => paint(canvas, frame / _frames),
    );
  }
}

Future<void> _loadFonts() async {
  Future<void> load(String family, String file) async {
    final font = File('build/readme_fonts/$file');
    if (!font.existsSync()) {
      throw StateError(
        'Missing ${font.path}. Run ./tool/generate_assets.sh to fetch fonts.',
      );
    }
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
    await loader.load();
  }

  await load('Display', 'Manrope.ttf');
  await load('Mono', 'DMMono-Regular.ttf');
  await load('MonoMedium', 'DMMono-Medium.ttf');
}

void main() {
  test('render hsluv README assets', () async {
    await _loadFonts();

    await _render(_heroSize, 'assets/logo.png', _paintHero);

    final hsluvCylinder = _SolidMesh(
      columns: 72,
      reachOf: (_, _) => 1.0,
      colorOf: (h, l) => _hsluv(h, 100, l),
    );
    final hslCylinder = _SolidMesh(
      columns: 72,
      reachOf: (_, _) => 1.0,
      colorOf: (h, l) => _hsl(h, 100, l),
    );
    await _renderFrames(
      _solidSize,
      'hsluv_vs_hsl_solid',
      (canvas, t) => _paintHslVsHsluvSolid(
        canvas,
        t,
        hsluvMesh: hsluvCylinder,
        hslMesh: hslCylinder,
      ),
    );

    var maxChroma = 0.0;
    for (var l = 5.0; l <= 95.0; l += 2.5) {
      final g = ColorPicker.getPickerGeometry(l);
      maxChroma = math.max(maxChroma, g.outerCircleRadius);
    }
    final hsluvGamut = _SolidMesh(
      columns: 180,
      reachOf: (l, h) => Hsluv.maxChromaForLH(l, h) / maxChroma,
      colorOf: (h, l) => _hsluv(h, 100, l),
    );
    final hpluvSpindle = _SolidMesh(
      columns: 180,
      reachOf: (l, _) => Hsluv.maxSafeChromaForL(l) / maxChroma,
      colorOf: (h, l) => _hpluv(h, 100, l),
    );
    await _renderFrames(
      _solidSize,
      'hpluv_vs_hsluv_solid',
      (canvas, t) => _paintHpluvVsHsluvSolid(
        canvas,
        t,
        hsluvMesh: hsluvGamut,
        hpluvMesh: hpluvSpindle,
        maxChroma: maxChroma,
      ),
    );

    final hslSweep = _sweep((h) => _hsl(h, 88, 62));
    final hsluvSweep = _sweep((h) => _hsluv(h, 88, 62));
    await _renderFrames(
      _waveSize,
      'hsl_vs_hsluv',
      (canvas, t) =>
          _paintWaveform(canvas, t, hslSweep: hslSweep, hsluvSweep: hsluvSweep),
    );
  }, timeout: Timeout.none);
}
