// Generates the README visual assets for `hsluv`:
//   - assets/logo.png
//   - build/readme_frames/hsluv_vs_hsl_solid/*.png  -> assets/hsluv_vs_hsl_solid.webp
//   - build/readme_frames/hpluv_vs_hsluv_solid/*.png -> assets/hpluv_vs_hsluv_solid.webp
//   - build/readme_frames/hsl_vs_hsluv/*.png        -> assets/hsl_vs_hsluv.webp
//
// Run via `./tool/generate_assets.sh` (requires `flutter`, `ffmpeg`, and `img2webp`).

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show HSLColor;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hsluv/hsluv.dart';

const ui.Color _paper = ui.Color(0xFFF6F4EE);
const ui.Color _cardBg = ui.Color(0xFFFCFAF5);
const ui.Color _borderCol = ui.Color(0xFFE0DDD4);
const ui.Color _ink = ui.Color(0xFF191918);
const ui.Color _inkMuted = ui.Color(0xFF6B6A66);

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

void _paintSolid(
  ui.Canvas canvas,
  _Camera camera,
  _SolidMesh mesh,
  _Slice slice, {
  _SolidMesh? ghostCageMesh,
  List<double>? ghostSliceReach,
  bool drawCageRibs = false,
}) {
  final columns = mesh.columns;
  const cageRingEvery = 5;
  const cageRibEvery = 6;
  final rowsBelow = (slice.lightness / (100 / _SolidMesh.rows)).ceil();

  if (ghostCageMesh != null) {
    final backCage = ui.Path();
    ui.Offset cornerGhost(int row, int column) {
      final (x, y, _) = camera.project(
        mesh.hueOf(column),
        ghostCageMesh.reach[row * columns + column] * camera.radius,
        _SolidMesh.lightnessOf(row),
      );
      return ui.Offset(x, y);
    }

    for (var row = 5; row <= _SolidMesh.rows - 5; row += cageRingEvery) {
      backCage.addPolygon([
        for (var column = 0; column < columns; column++)
          cornerGhost(row, column),
      ], true);
    }
    canvas.drawPath(
      backCage,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..strokeJoin = ui.StrokeJoin.round
        ..color = _ink.withValues(alpha: 0.13),
    );
  }

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

    final indices = Uint16List(faces.length * 6);
    var cursor = 0;
    for (final face in faces) {
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

    canvas.drawVertices(
      ui.Vertices.raw(
        ui.VertexMode.triangles,
        positions,
        colors: colors,
        indices: indices,
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

  final sliceIndices = Uint16List(rings * columns * 6);
  var sliceCursor = 0;
  for (var ring = 0; ring < rings; ring++) {
    for (var column = 0; column < columns; column++) {
      final next = (column + 1) % columns;
      final a = ring * columns + column;
      final b = ring * columns + next;
      final c = (ring + 1) * columns + next;
      final d = (ring + 1) * columns + column;
      sliceIndices
        ..[sliceCursor++] = a
        ..[sliceCursor++] = b
        ..[sliceCursor++] = c
        ..[sliceCursor++] = a
        ..[sliceCursor++] = c
        ..[sliceCursor++] = d;
    }
  }
  canvas.drawVertices(
    ui.Vertices.raw(
      ui.VertexMode.triangles,
      slicePos,
      colors: slice.colors,
      indices: sliceIndices,
    ),
    ui.BlendMode.dst,
    ui.Paint(),
  );

  if (ghostSliceReach != null) {
    final outerEdge = ui.Path();
    for (var column = 0; column < columns; column++) {
      final (x, y, _) = camera.project(
        mesh.hueOf(column),
        ghostSliceReach[column] * camera.radius,
        slice.lightness,
      );
      if (column == 0) {
        outerEdge.moveTo(x, y);
      } else {
        outerEdge.lineTo(x, y);
      }
    }
    outerEdge.close();
    canvas.drawPath(
      outerEdge,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..strokeJoin = ui.StrokeJoin.round
        ..color = _ink.withValues(alpha: 0.28),
    );
  }

  canvas.drawPath(
    edge,
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = ui.StrokeJoin.round
      ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.82),
  );

  if (ghostCageMesh == null) {
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
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..strokeJoin = ui.StrokeJoin.round
        ..color = _ink.withValues(alpha: 0.16),
    );
  }
}

void _drawText(
  ui.Canvas canvas,
  String text,
  ui.Offset offset, {
  required ui.TextStyle style,
  ui.TextAlign align = ui.TextAlign.left,
  double maxWidth = 500,
}) {
  final builder =
      ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: align, maxLines: 2))
        ..pushStyle(style)
        ..addText(text);
  final p = builder.build()..layout(ui.ParagraphConstraints(width: maxWidth));
  final w = switch (align) {
    ui.TextAlign.center || ui.TextAlign.right => p.maxIntrinsicWidth + 4,
    _ => maxWidth,
  };
  p.layout(ui.ParagraphConstraints(width: w));
  final dx = switch (align) {
    ui.TextAlign.center => offset.dx - p.maxIntrinsicWidth / 2,
    ui.TextAlign.right => offset.dx - p.maxIntrinsicWidth,
    _ => offset.dx,
  };
  canvas.drawParagraph(p, ui.Offset(dx, offset.dy));
}

void _drawLightnessPill(
  ui.Canvas canvas,
  double width,
  double height,
  double l,
) {
  const pillW = 152.0;
  const pillH = 26.0;
  final pillRect = ui.RRect.fromRectAndRadius(
    ui.Rect.fromLTWH((width - pillW) / 2, height - 38, pillW, pillH),
    const ui.Radius.circular(999),
  );
  canvas.drawRRect(pillRect, ui.Paint()..color = _cardBg);
  canvas.drawRRect(
    pillRect,
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _borderCol,
  );
  final pb =
      ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: ui.TextAlign.left))
        ..pushStyle(
          ui.TextStyle(
            fontFamily: 'StudioSans',
            fontSize: 12,
            color: _inkMuted,
          ),
        )
        ..addText('lightness: ')
        ..pop()
        ..pushStyle(
          ui.TextStyle(
            fontFamily: 'StudioMono',
            fontSize: 12,
            fontWeight: ui.FontWeight.w700,
            color: _ink,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        )
        ..addText('${l.round().toString().padLeft(2)}%');
  final para = pb.build()..layout(const ui.ParagraphConstraints(width: pillW));
  canvas.drawParagraph(
    para,
    ui.Offset(
      width / 2 - para.maxIntrinsicWidth / 2,
      height - 38 + pillH / 2 - para.height / 2,
    ),
  );
}

ui.Color _toUiColor(List<double> rgb) => ui.Color.from(
  alpha: 1.0,
  red: rgb[0].clamp(0.0, 1.0),
  green: rgb[1].clamp(0.0, 1.0),
  blue: rgb[2].clamp(0.0, 1.0),
);

Future<void> _savePng(
  ui.PictureRecorder recorder,
  double width,
  double height,
  double dpr,
  String path,
) async {
  final pic = recorder.endRecording();
  final img = await pic.toImage((width * dpr).toInt(), (height * dpr).toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  pic.dispose();
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<void> _loadFonts() async {
  Future<void> tryLoad(String family, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    await loader.load();
  }

  await tryLoad('StudioSans', '/System/Library/Fonts/SFNS.ttf');
  await tryLoad('StudioMono', '/System/Library/Fonts/SFNSMono.ttf');
}

void main() {
  test('render hsluv README assets', () async {
    await _loadFonts();

    // 1. Hero banner (`assets/logo.png`).
    {
      const width = 760.0;
      const height = 210.0;
      const dpr = 2.0;
      const obsidian = ui.Color(0xFF12141A);
      const obsidianBorder = ui.Color(0xFF292C36);
      const cream = ui.Color(0xFFF6F4EE);
      const mutedCream = ui.Color(0xFF9EA0A8);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(dpr, dpr);

      final bgRect = ui.RRect.fromRectAndRadius(
        const ui.Rect.fromLTWH(2, 2, width - 4, height - 4),
        const ui.Radius.circular(24),
      );
      canvas.drawRRect(bgRect, ui.Paint()..color = obsidian);
      canvas.drawRRect(
        bgRect,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = obsidianBorder,
      );

      const cx = 132.0;
      const cy = height / 2;
      const outerRadius = 64.0;
      final geom = ColorPicker.getPickerGeometry(66.0);
      final badgeScale = outerRadius / geom.outerCircleRadius;

      const ringSteps = 120;
      for (var i = 0; i < ringSteps; i++) {
        final a0 = (i / ringSteps) * 2 * math.pi;
        final a1 = ((i + 1.5) / ringSteps) * 2 * math.pi;
        final hue = i * 360.0 / ringSteps;
        canvas.drawArc(
          ui.Rect.fromCircle(
            center: const ui.Offset(cx, cy),
            radius: outerRadius + 4,
          ),
          a0,
          a1 - a0,
          false,
          ui.Paint()
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..color = _toUiColor(Hsluv.hsluvToRgb([hue, 92.0, 68.0])),
        );
      }

      final polyPath = ui.Path();
      for (var i = 0; i < geom.vertices.length; i++) {
        final px = cx + geom.vertices[i].x * badgeScale;
        final py = cy - geom.vertices[i].y * badgeScale;
        if (i == 0) {
          polyPath.moveTo(px, py);
        } else {
          polyPath.lineTo(px, py);
        }
      }
      polyPath.close();

      final sweepColors = [
        for (var i = 0; i <= 72; i++)
          _toUiColor(Hsluv.hsluvToRgb([(i * 5.0) % 360.0, 95.0, 68.0])),
      ];
      canvas.save();
      canvas.clipPath(polyPath);
      canvas.drawCircle(
        const ui.Offset(cx, cy),
        outerRadius,
        ui.Paint()
          ..shader = ui.Gradient.sweep(const ui.Offset(cx, cy), sweepColors, [
            for (var i = 0; i <= 72; i++) i / 72,
          ]),
      );
      canvas.drawCircle(
        const ui.Offset(cx, cy),
        outerRadius,
        ui.Paint()
          ..shader = ui.Gradient.radial(
            const ui.Offset(cx, cy),
            outerRadius * 0.9,
            [const ui.Color(0xFFFFFFFF), const ui.Color(0x00FFFFFF)],
            const [0.0, 0.85],
          ),
      );
      canvas.restore();

      final innerR = geom.innerCircleRadius * badgeScale;
      canvas.drawCircle(
        const ui.Offset(cx, cy),
        innerR,
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.9),
      );

      _drawText(
        canvas,
        'HSLuv',
        const ui.Offset(244, 54),
        style: ui.TextStyle(
          fontFamily: 'StudioSans',
          fontSize: 48,
          fontWeight: ui.FontWeight.w700,
          color: cream,
          letterSpacing: -1.0,
        ),
      );
      _drawText(
        canvas,
        'Perceptually uniform color space for Dart & Flutter',
        const ui.Offset(246, 114),
        style: ui.TextStyle(
          fontFamily: 'StudioSans',
          fontSize: 16,
          color: mutedCream,
        ),
      );

      for (var i = 0; i < 8; i++) {
        final hue = i * 45.0;
        final c = _toUiColor(Hsluv.hsluvToRgb([hue, 88.0, 68.0]));
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(246 + i * 32.0, 149, 24, 9),
            const ui.Radius.circular(999),
          ),
          ui.Paint()..color = c,
        );
      }

      await _savePng(recorder, width, height, dpr, 'assets/logo.png');
    }

    // 2. 3D HSLuv vs HSL cylinder solid (`build/readme_frames/hsluv_vs_hsl_solid`).
    {
      final outDir = Directory('build/readme_frames/hsluv_vs_hsl_solid')
        ..createSync(recursive: true);

      final hsluvMesh = _SolidMesh(
        columns: 72,
        reachOf: (_, _) => 1.0,
        colorOf: (h, l) => _toUiColor(Hsluv.hsluvToRgb([h, 100.0, l])),
      );
      final hslMesh = _SolidMesh(
        columns: 72,
        reachOf: (_, _) => 1.0,
        colorOf: (h, l) => HSLColor.fromAHSL(1.0, h, 1.0, l / 100.0).toColor(),
      );

      const width = 760.0;
      const height = 430.0;
      const dpr = 2.0;
      const frames = 150;

      for (var frame = 0; frame < frames; frame++) {
        final t = frame / frames;
        final yaw = 0.65 + 2 * math.pi * t;
        final lightness = 62.5 + 22.5 * math.cos(2 * math.pi * t);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)..scale(dpr, dpr);
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, width, height),
          ui.Paint()..color = _paper,
        );

        const panelGap = 16.0;
        const outerPad = 18.0;
        const panelWidth = (width - outerPad * 2 - panelGap) / 2;
        const panelHeight = height - outerPad - 52;
        const panelRadius = ui.Radius.circular(18);

        for (final left in [outerPad, outerPad + panelWidth + panelGap]) {
          final rr = ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(left, outerPad, panelWidth, panelHeight),
            panelRadius,
          );
          canvas.drawRRect(rr, ui.Paint()..color = _cardBg);
          canvas.drawRRect(
            rr,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = _borderCol,
          );
        }

        const solidSize = ui.Size(panelWidth - 20, panelHeight - 66);
        _paintSolid(
          canvas,
          _Camera(
            yaw: yaw,
            size: solidSize,
            offset: const ui.Offset(outerPad + 10, outerPad + 56),
          ),
          hsluvMesh,
          _Slice(
            columns: 72,
            lightness: lightness,
            reachOf: (_) => 1.0,
            colorOf: (h, s) => _toUiColor(Hsluv.hsluvToRgb([h, s, lightness])),
          ),
          drawCageRibs: true,
        );
        _paintSolid(
          canvas,
          _Camera(
            yaw: yaw,
            size: solidSize,
            offset: const ui.Offset(
              outerPad + panelWidth + panelGap + 10,
              outerPad + 56,
            ),
          ),
          hslMesh,
          _Slice(
            columns: 72,
            lightness: lightness,
            reachOf: (_) => 1.0,
            colorOf: (h, s) => HSLColor.fromAHSL(
              1.0,
              h,
              s / 100.0,
              lightness / 100.0,
            ).toColor(),
          ),
          drawCageRibs: true,
        );

        for (final (left, title, subtitle) in [
          (outerPad, 'HSLuv', 'Uniform lightness'),
          (outerPad + panelWidth + panelGap, 'HSL', 'Uneven brightness'),
        ]) {
          _drawText(
            canvas,
            title,
            ui.Offset(left + panelWidth / 2, outerPad + 14),
            align: ui.TextAlign.center,
            style: ui.TextStyle(
              fontFamily: 'StudioSans',
              fontSize: 18,
              fontWeight: ui.FontWeight.w700,
              color: _ink,
              letterSpacing: -0.3,
            ),
          );
          _drawText(
            canvas,
            subtitle,
            ui.Offset(left + panelWidth / 2, outerPad + 38),
            align: ui.TextAlign.center,
            style: ui.TextStyle(
              fontFamily: 'StudioSans',
              fontSize: 12,
              fontWeight: ui.FontWeight.w500,
              color: _inkMuted,
            ),
          );
        }

        _drawLightnessPill(canvas, width, height, lightness);
        final name = frame.toString().padLeft(4, '0');
        await _savePng(
          recorder,
          width,
          height,
          dpr,
          '${outDir.path}/frame_$name.png',
        );
      }
    }

    // 3. 3D HSLuv vs HPLuv in CIELUV C* (`build/readme_frames/hpluv_vs_hsluv_solid`).
    {
      final outDir = Directory('build/readme_frames/hpluv_vs_hsluv_solid')
        ..createSync(recursive: true);

      var maxChroma = 0.0;
      for (var l = 5.0; l <= 95.0; l += 2.5) {
        final g = ColorPicker.getPickerGeometry(l);
        if (g.outerCircleRadius > maxChroma) maxChroma = g.outerCircleRadius;
      }

      final hsluvMesh = _SolidMesh(
        columns: 180,
        reachOf: (l, h) => Hsluv.maxChromaForLH(l, h) / maxChroma,
        colorOf: (h, l) => _toUiColor(Hsluv.hsluvToRgb([h, 100.0, l])),
      );
      final hpluvMesh = _SolidMesh(
        columns: 180,
        reachOf: (l, _) => Hsluv.maxSafeChromaForL(l) / maxChroma,
        colorOf: (h, l) => _toUiColor(Hsluv.hpluvToRgb([h, 100.0, l])),
      );

      const width = 760.0;
      const height = 430.0;
      const dpr = 2.0;
      const frames = 150;

      for (var frame = 0; frame < frames; frame++) {
        final t = frame / frames;
        final yaw = 0.65 + 2 * math.pi * t;
        final lightness = 62.5 + 22.5 * math.cos(2 * math.pi * t);

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)..scale(dpr, dpr);
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, width, height),
          ui.Paint()..color = _paper,
        );

        const panelGap = 16.0;
        const outerPad = 18.0;
        const panelWidth = (width - outerPad * 2 - panelGap) / 2;
        const panelHeight = height - outerPad - 52;
        const panelRadius = ui.Radius.circular(18);

        for (final left in [outerPad, outerPad + panelWidth + panelGap]) {
          final rr = ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(left, outerPad, panelWidth, panelHeight),
            panelRadius,
          );
          canvas.drawRRect(rr, ui.Paint()..color = _cardBg);
          canvas.drawRRect(
            rr,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = _borderCol,
          );
        }

        const solidSize = ui.Size(panelWidth - 16, panelHeight - 66);
        final outerSliceReach = [
          for (var c = 0; c < hsluvMesh.columns; c++)
            Hsluv.maxChromaForLH(lightness, hsluvMesh.hueOf(c)) / maxChroma,
        ];
        final innerRadiusNorm = Hsluv.maxSafeChromaForL(lightness) / maxChroma;

        _paintSolid(
          canvas,
          _Camera(
            yaw: yaw,
            size: solidSize,
            offset: const ui.Offset(outerPad + 8, outerPad + 56),
            radius: 0.68,
            pitch: 0.48,
          ),
          hsluvMesh,
          _Slice(
            columns: hsluvMesh.columns,
            lightness: lightness,
            reachOf: (h) => Hsluv.maxChromaForLH(lightness, h) / maxChroma,
            colorOf: (h, s) => _toUiColor(Hsluv.hsluvToRgb([h, s, lightness])),
          ),
        );
        _paintSolid(
          canvas,
          _Camera(
            yaw: yaw,
            size: solidSize,
            offset: const ui.Offset(
              outerPad + panelWidth + panelGap + 8,
              outerPad + 56,
            ),
            radius: 0.68,
            pitch: 0.48,
          ),
          hpluvMesh,
          _Slice(
            columns: hpluvMesh.columns,
            lightness: lightness,
            reachOf: (_) => innerRadiusNorm,
            colorOf: (h, s) => _toUiColor(Hsluv.hpluvToRgb([h, s, lightness])),
          ),
          ghostCageMesh: hsluvMesh,
          ghostSliceReach: outerSliceReach,
        );

        for (final (left, title, subtitle) in [
          (outerPad, 'HSLuv', 'CIELUV C* reaches sRGB edge'),
          (
            outerPad + panelWidth + panelGap,
            'HPLuv',
            'CIELUV C* stays equal (pastel)',
          ),
        ]) {
          _drawText(
            canvas,
            title,
            ui.Offset(left + panelWidth / 2, outerPad + 14),
            align: ui.TextAlign.center,
            style: ui.TextStyle(
              fontFamily: 'StudioSans',
              fontSize: 18,
              fontWeight: ui.FontWeight.w700,
              color: _ink,
              letterSpacing: -0.3,
            ),
          );
          _drawText(
            canvas,
            subtitle,
            ui.Offset(left + panelWidth / 2, outerPad + 38),
            align: ui.TextAlign.center,
            style: ui.TextStyle(
              fontFamily: 'StudioSans',
              fontSize: 12,
              fontWeight: ui.FontWeight.w500,
              color: _inkMuted,
            ),
          );
        }

        _drawLightnessPill(canvas, width, height, lightness);
        final name = frame.toString().padLeft(4, '0');
        await _savePng(
          recorder,
          width,
          height,
          dpr,
          '${outDir.path}/frame_$name.png',
        );
      }
    }

    // 4. HSL vs HSLuv hue & L* waveform (`build/readme_frames/hsl_vs_hsluv`).
    {
      final outDir = Directory('build/readme_frames/hsl_vs_hsluv')
        ..createSync(recursive: true);

      const width = 760.0;
      const height = 430.0;
      const dpr = 2.0;
      const frames = 150;
      const barSteps = 180;

      final hslBarColors = [
        for (var i = 0; i <= barSteps; i++)
          HSLColor.fromAHSL(
            1.0,
            (i * 360.0 / barSteps) % 360.0,
            0.88,
            0.62,
          ).toColor(),
      ];
      final hsluvBarColors = [
        for (var i = 0; i <= barSteps; i++)
          HSLuvColor.fromHSL(
            (i * 360.0 / barSteps) % 360.0,
            88.0,
            62.0,
          ).toColor(),
      ];
      final hslLstarCurve = [
        for (var i = 0; i <= barSteps; i++)
          Hsluv.yToL(hslBarColors[i].computeLuminance()),
      ];
      final hsluvLstarCurve = [
        for (var i = 0; i <= barSteps; i++)
          Hsluv.yToL(hsluvBarColors[i].computeLuminance()),
      ];
      final barStops = [for (var i = 0; i <= barSteps; i++) i / barSteps];

      for (var frame = 0; frame < frames; frame++) {
        final t = frame / frames;
        final hue = (t * 360.0) % 360.0;
        final hslColor = HSLColor.fromAHSL(1.0, hue, 0.88, 0.62).toColor();
        final hsluvColor = HSLuvColor.fromHSL(hue, 88.0, 62.0).toColor();
        final hslLstar = Hsluv.yToL(hslColor.computeLuminance());
        final hsluvLstar = Hsluv.yToL(hsluvColor.computeLuminance());

        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)..scale(dpr, dpr);
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, width, height),
          ui.Paint()..color = _paper,
        );

        void paintWaveformCard({
          required double topY,
          required String title,
          required String subtitle,
          required ui.Color activeColor,
          required double lStar,
          required List<ui.Color> barColors,
          required List<double> curve,
        }) {
          const padX = 18.0;
          const cardW = width - padX * 2;
          const cardH = 188.0;
          final rr = ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(padX, topY, cardW, cardH),
            const ui.Radius.circular(18),
          );
          canvas.drawRRect(rr, ui.Paint()..color = _cardBg);
          canvas.drawRRect(
            rr,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = _borderCol,
          );

          const swatchW = 104.0;
          final swatchX = padX + 20;
          final swatchRect = ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(swatchX, topY + 22, swatchW, 108),
            const ui.Radius.circular(16),
          );
          canvas.drawRRect(swatchRect, ui.Paint()..color = activeColor);
          canvas.drawRRect(
            swatchRect,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = _ink.withValues(alpha: 0.1),
          );

          final statRect = ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(swatchX, topY + 140, swatchW, 26),
            const ui.Radius.circular(999),
          );
          canvas.drawRRect(statRect, ui.Paint()..color = _paper);
          canvas.drawRRect(
            statRect,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = _borderCol,
          );
          _drawText(
            canvas,
            'L*: ${lStar.round().toString().padLeft(2)}%',
            ui.Offset(swatchX + swatchW / 2, topY + 146),
            align: ui.TextAlign.center,
            style: ui.TextStyle(
              fontFamily: 'StudioMono',
              fontSize: 12,
              fontWeight: ui.FontWeight.w700,
              color: _ink,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          );

          final contentX = swatchX + swatchW + 22;
          final contentW = cardW - 40 - swatchW - 22;

          _drawText(
            canvas,
            title,
            ui.Offset(contentX, topY + 20),
            style: ui.TextStyle(
              fontFamily: 'StudioSans',
              fontSize: 17,
              fontWeight: ui.FontWeight.w700,
              color: _ink,
            ),
          );
          _drawText(
            canvas,
            subtitle,
            ui.Offset(contentX + 74, topY + 23),
            style: ui.TextStyle(
              fontFamily: 'StudioSans',
              fontSize: 12.5,
              color: _inkMuted,
            ),
          );
          _drawText(
            canvas,
            'hue ${hue.round().toString().padLeft(3)}°',
            ui.Offset(contentX + contentW, topY + 23),
            align: ui.TextAlign.right,
            style: ui.TextStyle(
              fontFamily: 'StudioMono',
              fontSize: 12,
              fontWeight: ui.FontWeight.w500,
              color: _inkMuted,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          );

          const barH = 24.0;
          final barTop = topY + 52;
          final barRect = ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(contentX, barTop, contentW, barH),
            const ui.Radius.circular(999),
          );
          canvas.drawRRect(
            barRect,
            ui.Paint()
              ..shader = ui.Gradient.linear(
                ui.Offset(contentX, 0),
                ui.Offset(contentX + contentW, 0),
                barColors,
                barStops,
              ),
          );
          canvas.drawRRect(
            barRect,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = _ink.withValues(alpha: 0.08),
          );

          final chartTop = topY + 92;
          const chartH = 74.0;
          final chartRect = ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(contentX, chartTop, contentW, chartH),
            const ui.Radius.circular(10),
          );
          canvas.drawRRect(chartRect, ui.Paint()..color = _paper);
          canvas.drawRRect(
            chartRect,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = _borderCol,
          );

          for (final level in [25.0, 50.0, 75.0]) {
            final gy = chartTop + chartH * (1.0 - level / 100.0);
            canvas.drawLine(
              ui.Offset(contentX + 6, gy),
              ui.Offset(contentX + contentW - 6, gy),
              ui.Paint()
                ..strokeWidth = 0.8
                ..color = _borderCol,
            );
          }

          final linePath = ui.Path();
          final areaPath = ui.Path();
          for (var i = 0; i <= barSteps; i++) {
            final px = contentX + (i / barSteps) * contentW;
            final py =
                chartTop + chartH * (1.0 - curve[i].clamp(0.0, 100.0) / 100.0);
            if (i == 0) {
              linePath.moveTo(px, py);
              areaPath.moveTo(px, chartTop + chartH);
              areaPath.lineTo(px, py);
            } else {
              linePath.lineTo(px, py);
              areaPath.lineTo(px, py);
            }
          }
          areaPath
            ..lineTo(contentX + contentW, chartTop + chartH)
            ..close();

          canvas.save();
          canvas.clipRRect(chartRect);
          canvas.drawPath(
            areaPath,
            ui.Paint()..color = activeColor.withValues(alpha: 0.18),
          );
          canvas.drawPath(
            linePath,
            ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..strokeJoin = ui.StrokeJoin.round
              ..color = _ink.withValues(alpha: 0.85),
          );
          canvas.restore();

          final curX = contentX + (hue / 360.0) * contentW;
          final curY =
              chartTop + chartH * (1.0 - lStar.clamp(0.0, 100.0) / 100.0);

          canvas.drawLine(
            ui.Offset(curX, barTop + barH),
            ui.Offset(curX, chartTop + chartH),
            ui.Paint()
              ..strokeWidth = 1.1
              ..color = _ink.withValues(alpha: 0.25),
          );

          final barCenter = ui.Offset(curX, barTop + barH / 2);
          canvas.drawCircle(
            barCenter,
            9.5,
            ui.Paint()..color = const ui.Color(0xFFFFFFFF),
          );
          canvas.drawCircle(barCenter, 6.0, ui.Paint()..color = activeColor);

          canvas.drawCircle(
            ui.Offset(curX, curY),
            6.5,
            ui.Paint()..color = const ui.Color(0xFFFFFFFF),
          );
          canvas.drawCircle(
            ui.Offset(curX, curY),
            4.5,
            ui.Paint()..color = _ink,
          );

          _drawText(
            canvas,
            'perceived lightness (L*)',
            ui.Offset(contentX + 8, chartTop + chartH - 18),
            style: ui.TextStyle(
              fontFamily: 'StudioSans',
              fontSize: 10.5,
              fontWeight: ui.FontWeight.w500,
              color: _inkMuted,
            ),
          );
        }

        paintWaveformCard(
          topY: 18,
          title: 'HSL',
          subtitle: 'S: 88%  L: 62% · lightness fluctuates',
          activeColor: hslColor,
          lStar: hslLstar,
          barColors: hslBarColors,
          curve: hslLstarCurve,
        );
        paintWaveformCard(
          topY: 224,
          title: 'HSLuv',
          subtitle: 'S: 88%  L: 62% · constant lightness',
          activeColor: hsluvColor,
          lStar: hsluvLstar,
          barColors: hsluvBarColors,
          curve: hsluvLstarCurve,
        );

        final name = frame.toString().padLeft(4, '0');
        await _savePng(
          recorder,
          width,
          height,
          dpr,
          '${outDir.path}/frame_$name.png',
        );
      }
    }
  });
}
