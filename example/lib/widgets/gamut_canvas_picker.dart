import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:hsluv/color_picker.dart';
import 'package:hsluv/geometry.dart';
import 'package:hsluv/hsluv.dart';
import 'package:hsluv/hsluvcolor.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:material_ui/material_ui.dart';

import '../models/accessibility_utils.dart';
import '../models/color_spaces.dart';
import 'studio_theme.dart';

enum _Gamut2DMode { polarSlice, hueLightnessMatrix }

/// Interactive 2D perceptual gamut picker offering both a Polar Gamut slice
/// (backed by [ColorPicker.getPickerGeometry] & [ColorPicker.closestPoint] in HSLuv)
/// and a Hue × Lightness/Tone 2D matrix, plus a horizontal scrub strip for the 3rd axis.
class GamutCanvasPicker extends StatefulWidget {
  const GamutCanvasPicker({
    super.key,
    required this.space,
    required this.activeColor,
    required this.onScrubStart,
    required this.onScrubChannel,
    required this.onScrubHsluvHueSat,
    required this.onScrubTwoChannels,
    required this.onScrubEnd,
    this.embeddedOnStage = false,
    this.stageInk,
  });

  final ColorSpaceMode space;
  final StudioColor activeColor;
  final VoidCallback onScrubStart;
  final void Function(int channelIndex, double value) onScrubChannel;
  final void Function(double hue, double saturation) onScrubHsluvHueSat;
  final void Function({
    required int xChannel,
    required double xValue,
    required int yChannel,
    required double yValue,
  }) onScrubTwoChannels;
  final VoidCallback onScrubEnd;
  final bool embeddedOnStage;
  final Color? stageInk;

  @override
  State<GamutCanvasPicker> createState() => _GamutCanvasPickerState();
}

class _GamutCanvasPickerState extends State<GamutCanvasPicker>
    with SingleTickerProviderStateMixin {
  _Gamut2DMode _mode = _Gamut2DMode.polarSlice;
  bool _isDragging = false;

  late final AnimationController _flingController;
  Offset? _lastCanvasOffset;
  Size? _lastCanvasSize;
  Offset? _flingStartOffset;
  Offset? _flingDelta;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )
      ..addListener(_onFlingTick)
      ..addStatusListener(_onFlingStatus);
  }

  @override
  void dispose() {
    _flingController
      ..removeListener(_onFlingTick)
      ..removeStatusListener(_onFlingStatus)
      ..dispose();
    super.dispose();
  }

  void _stopActiveFling({bool finalizeScrub = true}) {
    if (_flingController.isAnimating) {
      _flingController.stop();
      if (finalizeScrub) {
        widget.onScrubEnd();
      }
    }
  }

  void _onFlingTick() {
    final start = _flingStartOffset;
    final size = _lastCanvasSize;
    final delta = _flingDelta;
    if (start == null || size == null || delta == null) return;
    final curvedT = Curves.decelerate.transform(_flingController.value);
    final pos = start + delta * curvedT;
    if (_mode == _Gamut2DMode.polarSlice) {
      _applyPolarPoint(pos, size);
    } else {
      _applyMatrixPoint(pos, size);
    }
  }

  void _onFlingStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        setState(() => _isDragging = false);
      }
      widget.onScrubEnd();
    }
  }

  void _applyPolarPoint(Offset localPos, Size size, {bool haptic = false}) {
    final radius = math.min(size.width, size.height) * 0.40;
    if (radius <= 4) return;
    final center = Offset(size.width / 2, size.height / 2);
    final lightness = widget.activeColor.channelsFor(widget.space)[2].value;
    final dx = localPos.dx - center.dx;
    final dy = -(localPos.dy - center.dy); // math +y is up

    if (widget.space == ColorSpaceMode.hsluv) {
      final effectiveL = lightness.clamp(1.0, 99.0);
      final geometry = ColorPicker.getPickerGeometry(effectiveL);
      final maxR = math.max(geometry.outerCircleRadius, 1.0);
      final scale = radius / maxR;
      final rawPt = Point(dx / scale, dy / scale);
      final clampedPt = ColorPicker.closestPoint(geometry, rawPt);
      final angle =
          (math.atan2(clampedPt.y, clampedPt.x) * 180 / math.pi + 360) % 360;
      final chroma = math.sqrt(
        clampedPt.x * clampedPt.x + clampedPt.y * clampedPt.y,
      );
      final maxC = Hsluv.maxChromaForLH(effectiveL, angle);
      final sat = maxC > 0 ? (chroma / maxC * 100.0).clamp(0.0, 100.0) : 0.0;
      if (haptic) HapticFeedback.selectionClick();
      widget.onScrubHsluvHueSat(angle, sat);
      return;
    }

    if (widget.space == ColorSpaceMode.oklch) {
      const double scaleMaxC = 0.37;
      final hue = (math.atan2(dy, dx) * 180 / math.pi + 360) % 360;
      final dist = math.sqrt(dx * dx + dy * dy);
      final rawC = (dist / radius) * scaleMaxC;
      final maxC = OklchColor.maxChromaForLH(lightness.clamp(1.0, 99.0), hue);
      final clampedC = rawC.clamp(0.0, maxC);
      final satPct =
          maxC > 0 ? (clampedC / maxC * 100.0).clamp(0.0, 100.0) : 0.0;
      if (haptic) HapticFeedback.selectionClick();
      widget.onScrubTwoChannels(
        xChannel: 0,
        xValue: hue,
        yChannel: 1,
        yValue: satPct,
      );
      return;
    }

    if (widget.space == ColorSpaceMode.hct) {
      const double scaleMaxC = 115.0;
      final hue = (math.atan2(dy, dx) * 180 / math.pi + 360) % 360;
      final dist = math.sqrt(dx * dx + dy * dy);
      final rawC = (dist / radius) * scaleMaxC;
      final maxC = Hct.from(hue, 150.0, lightness.clamp(1.0, 99.0)).chroma;
      final clampedC = rawC.clamp(0.0, math.max(maxC, 0.0)).toDouble();
      if (haptic) HapticFeedback.selectionClick();
      widget.onScrubTwoChannels(
        xChannel: 0,
        xValue: hue,
        yChannel: 1,
        yValue: clampedC,
      );
      return;
    }

    // HSL / HSV uniform polar disk
    final hue = (math.atan2(dy, dx) * 180 / math.pi + 360) % 360;
    final dist = math.sqrt(dx * dx + dy * dy);
    final sat = (dist / radius * 100.0).clamp(0.0, 100.0);
    if (haptic) HapticFeedback.selectionClick();
    widget.onScrubTwoChannels(
      xChannel: 0,
      xValue: hue,
      yChannel: 1,
      yValue: sat,
    );
  }

  void _applyMatrixPoint(Offset localPos, Size size, {bool haptic = false}) {
    if (size.width <= 1 || size.height <= 1) return;
    final hue = (localPos.dx / size.width).clamp(0.0, 1.0) * 360.0;
    final l = (1.0 - (localPos.dy / size.height).clamp(0.0, 1.0)) * 100.0;
    if (haptic) HapticFeedback.selectionClick();
    widget.onScrubTwoChannels(
      xChannel: 0,
      xValue: hue,
      yChannel: 2,
      yValue: l,
    );
  }

  void _handlePanEnd(DragEndDetails details) {
    final v = details.velocity.pixelsPerSecond;
    final start = _lastCanvasOffset;
    final size = _lastCanvasSize;
    if (v.distance > 100 && start != null && size != null) {
      _flingStartOffset = start;
      _flingDelta = v * 0.18;
      _flingController.forward(from: 0);
      return;
    }
    setState(() => _isDragging = false);
    widget.onScrubEnd();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final channels = widget.activeColor.channelsFor(widget.space);
    final thirdChannel = _mode == _Gamut2DMode.polarSlice
        ? channels[2]
        : channels[1];
    final embedded = widget.embeddedOnStage;
    final ink = widget.stageInk ?? scheme.onSurface;

    return Container(
      decoration: embedded
          ? null
          : BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isDragging
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.45),
                width: _isDragging ? 1.5 : 1,
              ),
            ),
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!embedded) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mode == _Gamut2DMode.polarSlice
                            ? '${widget.space.label} Gamut Slice'
                            : '${widget.space.label} Hue × ${channels[2].name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          color: ink.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        _mode == _Gamut2DMode.polarSlice
                            ? _polarSubtitle()
                            : 'Drag Hue & ${channels[2].name} at constant ${channels[1].name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StudioPillSelector<_Gamut2DMode>(
                  compact: true,
                  value: _mode,
                  options: const [
                    StudioPillOption(
                      value: _Gamut2DMode.polarSlice,
                      icon: Icons.radar_rounded,
                      label: 'Polar',
                    ),
                    StudioPillOption(
                      value: _Gamut2DMode.hueLightnessMatrix,
                      icon: Icons.grid_on_rounded,
                      label: 'Matrix',
                    ),
                  ],
                  onChanged: (val) => setState(() => _mode = val),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                return embedded || _mode == _Gamut2DMode.polarSlice
                    ? _buildPolarCanvas(context, size, channels)
                    : _buildMatrixCanvas(context, size, channels);
              },
            ),
          ),
          if (!embedded) ...[
            const SizedBox(height: 10),
            _HorizontalChannelScrubber(
              descriptor: thirdChannel,
              space: widget.space,
              activeColor: widget.activeColor,
              onScrubStart: widget.onScrubStart,
              onScrubUpdate: (v) =>
                  widget.onScrubChannel(thirdChannel.index, v),
              onScrubEnd: widget.onScrubEnd,
            ),
          ],
        ],
      ),
    );
  }

  String _polarSubtitle() {
    switch (widget.space) {
      case ColorSpaceMode.hsluv:
        return 'Exact CIELUV sRGB gamut polygon + HPLuv pastel inner circle';
      case ColorSpaceMode.oklch:
        return 'True OKLCH sRGB chroma boundary (dotted ring = C 0.37)';
      case ColorSpaceMode.hct:
        return 'Material HCT chroma gamut boundary at fixed Tone';
      case ColorSpaceMode.hsl:
      case ColorSpaceMode.hsv:
        return 'Polar Hue × ${widget.space.channelNames[1]} slice';
    }
  }

  Widget _buildPolarCanvas(
    BuildContext context,
    Size size,
    List<ChannelDescriptor> channels,
  ) {
    final lightness = channels[2].value;

    return MouseRegion(
      cursor:
          _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          _stopActiveFling();
          _lastCanvasOffset = d.localPosition;
          _lastCanvasSize = size;
          setState(() => _isDragging = true);
          widget.onScrubStart();
          _applyPolarPoint(d.localPosition, size, haptic: true);
        },
        onPanUpdate: (d) {
          _lastCanvasOffset = d.localPosition;
          _lastCanvasSize = size;
          _applyPolarPoint(d.localPosition, size);
        },
        onPanEnd: _handlePanEnd,
        onPanCancel: () {
          _stopActiveFling(finalizeScrub: false);
          setState(() => _isDragging = false);
          widget.onScrubEnd();
        },
        onTapUp: (d) {
          _stopActiveFling();
          _lastCanvasOffset = d.localPosition;
          _lastCanvasSize = size;
          widget.onScrubStart();
          _applyPolarPoint(d.localPosition, size, haptic: true);
          widget.onScrubEnd();
        },
        child: CustomPaint(
          size: size,
          painter: _PolarGamutPainter(
            space: widget.space,
            activeColor: widget.activeColor,
            lightness: lightness,
            isDragging: _isDragging,
            outlineColor:
                widget.stageInk ?? Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildMatrixCanvas(
    BuildContext context,
    Size size,
    List<ChannelDescriptor> channels,
  ) {
    final satValue = channels[1].value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: MouseRegion(
        cursor:
            _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            _stopActiveFling();
            _lastCanvasOffset = d.localPosition;
            _lastCanvasSize = size;
            setState(() => _isDragging = true);
            widget.onScrubStart();
            _applyMatrixPoint(d.localPosition, size, haptic: true);
          },
          onPanUpdate: (d) {
            _lastCanvasOffset = d.localPosition;
            _lastCanvasSize = size;
            _applyMatrixPoint(d.localPosition, size);
          },
          onPanEnd: _handlePanEnd,
          onPanCancel: () {
            _stopActiveFling(finalizeScrub: false);
            setState(() => _isDragging = false);
            widget.onScrubEnd();
          },
          onTapUp: (d) {
            _stopActiveFling();
            _lastCanvasOffset = d.localPosition;
            _lastCanvasSize = size;
            widget.onScrubStart();
            _applyMatrixPoint(d.localPosition, size, haptic: true);
            widget.onScrubEnd();
          },
          child: CustomPaint(
            size: size,
            painter: _HueLightnessMatrixPainter(
              space: widget.space,
              activeColor: widget.activeColor,
              fixedSatOrChroma: satValue,
              currentHue: channels[0].value,
              currentLightness: channels[2].value,
              isDragging: _isDragging,
            ),
          ),
        ),
      ),
    );
  }
}

class _PolarGamutPainter extends CustomPainter {
  const _PolarGamutPainter({
    required this.space,
    required this.activeColor,
    required this.lightness,
    required this.isDragging,
    required this.outlineColor,
  });

  final ColorSpaceMode space;
  final StudioColor activeColor;
  final double lightness;
  final bool isDragging;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width, size.height) * 0.40;
    if (radius <= 4) return;
    final center = Offset(size.width / 2, size.height / 2);

    // Outer subtle reference circle
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = outlineColor.withValues(alpha: 0.25);
    canvas.drawCircle(center, radius, ringPaint);
    canvas.drawCircle(center, radius * 0.5, ringPaint);

    // Subtle compass crosshairs
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      ringPaint,
    );

    // Delicate 0° / 90° / 180° / 270° compass markers
    _drawCompassLabel(canvas, '0°', Offset(center.dx + radius + 5, center.dy - 6));
    _drawCompassLabel(canvas, '90°', Offset(center.dx - 8, center.dy - radius - 14));
    _drawCompassLabel(canvas, '180°', Offset(center.dx - radius - 26, center.dy - 6));
    _drawCompassLabel(canvas, '270°', Offset(center.dx - 11, center.dy + radius + 3));

    final effectiveL = lightness.clamp(1.0, 99.0);
    final geometry = space == ColorSpaceMode.hsluv
        ? ColorPicker.getPickerGeometry(effectiveL)
        : null;

    const angularSteps = 72;
    const radialRings = 8;

    final maxBoundaryRadius = <double>[];
    final maxBoundaryHueColors = <Color>[];
    final boundaryPoints = <Offset>[];

    for (int i = 0; i < angularSteps; i++) {
      final hue = (i / angularSteps) * 360.0;
      final double rNorm;
      final Color edgeColor;

      switch (space) {
        case ColorSpaceMode.hsluv:
          final maxC = Hsluv.maxChromaForLH(effectiveL, hue);
          final maxOuter = math.max(geometry!.outerCircleRadius, 1.0);
          rNorm = (maxC / maxOuter).clamp(0.0, 1.05);
          edgeColor = HSLuvColor.fromHSL(
            hue.clamp(0.0, 360.0),
            100.0,
            lightness.clamp(0.0, 100.0),
          ).toColor();
          break;
        case ColorSpaceMode.oklch:
          final maxC = OklchColor.maxChromaForLH(effectiveL, hue);
          rNorm = (maxC / 0.37).clamp(0.0, 1.05);
          edgeColor = OklchColor.fromRelative(
            hue: hue,
            saturationPercent: 100.0,
            lightness: lightness,
          ).toColor();
          break;
        case ColorSpaceMode.hct:
          final maxC = Hct.from(hue, 150.0, effectiveL).chroma;
          rNorm = (maxC / 115.0).clamp(0.0, 1.05);
          edgeColor = Color(Hct.from(hue, maxC, lightness).toInt());
          break;
        case ColorSpaceMode.hsl:
          rNorm = 1.0;
          edgeColor = HSLColor.fromAHSL(
            1.0,
            hue,
            1.0,
            (lightness / 100.0).clamp(0.0, 1.0),
          ).toColor();
          break;
        case ColorSpaceMode.hsv:
          rNorm = 1.0;
          edgeColor = HSVColor.fromAHSV(
            1.0,
            hue,
            1.0,
            (lightness / 100.0).clamp(0.0, 1.0),
          ).toColor();
          break;
      }

      maxBoundaryRadius.add(rNorm * radius);
      maxBoundaryHueColors.add(edgeColor);

      final rad = hue * math.pi / 180.0;
      boundaryPoints.add(
        Offset(
          center.dx + math.cos(rad) * rNorm * radius,
          center.dy - math.sin(rad) * rNorm * radius,
        ),
      );
    }

    // Build triangular mesh (BlendMode.dst renders pure vertex colors)
    final positions = <Offset>[];
    final colors = <Color>[];
    final centerColor = _centerNeutralColor();

    Color sampleAt(double hue, double frac) {
      switch (space) {
        case ColorSpaceMode.hsluv:
          return HSLuvColor.fromHSL(
            hue.clamp(0.0, 360.0),
            (frac * 100.0).clamp(0.0, 100.0),
            lightness.clamp(0.0, 100.0),
          ).toColor();
        case ColorSpaceMode.oklch:
          return OklchColor.fromRelative(
            hue: hue,
            saturationPercent: frac * 100.0,
            lightness: lightness,
          ).toColor();
        case ColorSpaceMode.hct:
          final maxC = Hct.from(hue, 150.0, effectiveL).chroma;
          return Color(Hct.from(hue, maxC * frac, lightness).toInt());
        case ColorSpaceMode.hsl:
          return HSLColor.fromAHSL(
            1.0,
            hue,
            frac,
            (lightness / 100.0).clamp(0.0, 1.0),
          ).toColor();
        case ColorSpaceMode.hsv:
          return HSVColor.fromAHSV(
            1.0,
            hue,
            frac,
            (lightness / 100.0).clamp(0.0, 1.0),
          ).toColor();
      }
    }

    // Precompute ring grid [angularSteps][radialRings]
    final ringOffsets = List<List<Offset>>.generate(angularSteps, (i) {
      final rad = (i / angularSteps) * 2 * math.pi;
      final rMax = maxBoundaryRadius[i];
      final cosR = math.cos(rad);
      final sinR = math.sin(rad);
      return List<Offset>.generate(radialRings, (ring) {
        final f = (ring + 1) / radialRings;
        return Offset(
          center.dx + cosR * rMax * f,
          center.dy - sinR * rMax * f,
        );
      });
    });

    final ringColors = List<List<Color>>.generate(angularSteps, (i) {
      final hue = (i / angularSteps) * 360.0;
      return List<Color>.generate(radialRings, (ring) {
        if (ring == radialRings - 1) return maxBoundaryHueColors[i];
        return sampleAt(hue, (ring + 1) / radialRings);
      });
    });

    for (int i = 0; i < angularSteps; i++) {
      final next = (i + 1) % angularSteps;
      // Inner triangle fan
      positions.addAll([
        center,
        ringOffsets[i][0],
        ringOffsets[next][0],
      ]);
      colors.addAll([
        centerColor,
        ringColors[i][0],
        ringColors[next][0],
      ]);

      // Concentric quads
      for (int r = 0; r < radialRings - 1; r++) {
        final a0 = ringOffsets[i][r];
        final a1 = ringOffsets[i][r + 1];
        final b0 = ringOffsets[next][r];
        final b1 = ringOffsets[next][r + 1];
        final ca0 = ringColors[i][r];
        final ca1 = ringColors[i][r + 1];
        final cb0 = ringColors[next][r];
        final cb1 = ringColors[next][r + 1];

        positions.addAll([a0, a1, b1, a0, b1, b0]);
        colors.addAll([ca0, ca1, cb1, ca0, cb1, cb0]);
      }
    }

    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      colors: colors,
    );
    canvas.drawVertices(vertices, BlendMode.dst, Paint());

    // Exact polygon outline for HSLuv / gamut border for OKLCH & HCT
    final boundaryPath = Path()..addPolygon(boundaryPoints, true);
    canvas.drawPath(
      boundaryPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = outlineColor.withValues(alpha: 0.38),
    );

    // Inner HPLuv pastel circle in HSLuv mode
    if (space == ColorSpaceMode.hsluv && geometry != null) {
      final innerRatio =
          geometry.innerCircleRadius / math.max(geometry.outerCircleRadius, 1.0);
      canvas.drawCircle(
        center,
        radius * innerRatio,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = contrastingTextColor(centerColor).withValues(alpha: 0.45),
      );
    }

    // Active thumb position
    final thumbOffset = _thumbOffset(center, radius, effectiveL, geometry);
    final thumbColor = activeColor.color;
    final ink = contrastingTextColor(thumbColor);

    canvas.drawCircle(
      thumbOffset,
      isDragging ? 13 : 10,
      Paint()..color = ink.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      thumbOffset,
      isDragging ? 10 : 7.5,
      Paint()..color = thumbColor,
    );
  }

  Color _centerNeutralColor() {
    switch (space) {
      case ColorSpaceMode.hsluv:
        return HSLuvColor.fromHSL(
          0.0,
          0.0,
          lightness.clamp(0.0, 100.0),
        ).toColor();
      case ColorSpaceMode.oklch:
        return OklchColor(lightness: lightness, chroma: 0, hue: 0).toColor();
      case ColorSpaceMode.hct:
        return Color(Hct.from(0, 0, lightness).toInt());
      case ColorSpaceMode.hsl:
        return HSLColor.fromAHSL(
          1.0,
          0,
          0,
          (lightness / 100.0).clamp(0.0, 1.0),
        ).toColor();
      case ColorSpaceMode.hsv:
        return HSVColor.fromAHSV(
          1.0,
          0,
          0,
          (lightness / 100.0).clamp(0.0, 1.0),
        ).toColor();
    }
  }

  Offset _thumbOffset(
    Offset center,
    double radius,
    double effectiveL,
    PickerGeometry? geometry,
  ) {
    final channels = activeColor.channelsFor(space);
    final hueRad = channels[0].value * math.pi / 180.0;
    final double rPx;

    switch (space) {
      case ColorSpaceMode.hsluv:
        final maxC = Hsluv.maxChromaForLH(effectiveL, channels[0].value);
        final c = maxC * (channels[1].value / 100.0);
        final maxOuter = math.max(geometry?.outerCircleRadius ?? 1.0, 1.0);
        rPx = (c / maxOuter) * radius;
        break;
      case ColorSpaceMode.oklch:
        rPx = (activeColor.oklch.chroma / 0.37) * radius;
        break;
      case ColorSpaceMode.hct:
        rPx = (activeColor.hctChroma / 115.0) * radius;
        break;
      case ColorSpaceMode.hsl:
      case ColorSpaceMode.hsv:
        rPx = (channels[1].value / 100.0) * radius;
        break;
    }

    return Offset(
      center.dx + math.cos(hueRad) * rPx,
      center.dy - math.sin(hueRad) * rPx,
    );
  }

  void _drawCompassLabel(Canvas canvas, String text, Offset offset) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          color: outlineColor.withValues(alpha: 0.52),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _PolarGamutPainter oldDelegate) {
    return oldDelegate.space != space ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.outlineColor != outlineColor;
  }
}

class _HueLightnessMatrixPainter extends CustomPainter {
  const _HueLightnessMatrixPainter({
    required this.space,
    required this.activeColor,
    required this.fixedSatOrChroma,
    required this.currentHue,
    required this.currentLightness,
    required this.isDragging,
  });

  final ColorSpaceMode space;
  final StudioColor activeColor;
  final double fixedSatOrChroma;
  final double currentHue;
  final double currentLightness;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 36;
    const rows = 20;

    final gridOffsets = List<List<Offset>>.generate(rows + 1, (r) {
      final y = (r / rows) * size.height;
      return List<Offset>.generate(cols + 1, (c) {
        final x = (c / cols) * size.width;
        return Offset(x, y);
      });
    });

    final gridColors = List<List<Color>>.generate(rows + 1, (r) {
      final l = (1.0 - r / rows) * 100.0;
      return List<Color>.generate(cols + 1, (c) {
        final h = (c / cols) * 360.0;
        return _sampleHueLightness(h, l);
      });
    });

    final positions = <Offset>[];
    final colors = <Color>[];
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final p00 = gridOffsets[r][c];
        final p10 = gridOffsets[r][c + 1];
        final p01 = gridOffsets[r + 1][c];
        final p11 = gridOffsets[r + 1][c + 1];
        final c00 = gridColors[r][c];
        final c10 = gridColors[r][c + 1];
        final c01 = gridColors[r + 1][c];
        final c11 = gridColors[r + 1][c + 1];
        positions.addAll([p00, p10, p11, p00, p11, p01]);
        colors.addAll([c00, c10, c11, c00, c11, c01]);
      }
    }

    canvas.drawVertices(
      ui.Vertices(ui.VertexMode.triangles, positions, colors: colors),
      BlendMode.dst,
      Paint(),
    );

    final thumbX = (currentHue / 360.0).clamp(0.0, 1.0) * size.width;
    final thumbY =
        (1.0 - (currentLightness / 100.0).clamp(0.0, 1.0)) * size.height;
    final thumb = Offset(thumbX, thumbY);
    final ink = contrastingTextColor(activeColor.color);

    final guidePaint = Paint()
      ..color = ink.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(thumb.dx, 0), Offset(thumb.dx, size.height), guidePaint);
    canvas.drawLine(Offset(0, thumb.dy), Offset(size.width, thumb.dy), guidePaint);

    canvas.drawCircle(
      thumb,
      isDragging ? 13 : 10,
      Paint()..color = ink.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      thumb,
      isDragging ? 10 : 7.5,
      Paint()..color = activeColor.color,
    );
  }

  Color _sampleHueLightness(double h, double l) {
    switch (space) {
      case ColorSpaceMode.hsluv:
        return HSLuvColor.fromHSL(
          h.clamp(0.0, 360.0),
          fixedSatOrChroma.clamp(0.0, 100.0),
          l.clamp(0.0, 100.0),
        ).toColor();
      case ColorSpaceMode.oklch:
        return OklchColor.fromRelative(
          hue: h,
          saturationPercent: fixedSatOrChroma,
          lightness: l,
        ).toColor();
      case ColorSpaceMode.hct:
        return Color(Hct.from(h, fixedSatOrChroma, l).toInt());
      case ColorSpaceMode.hsl:
        return HSLColor.fromAHSL(
          1.0,
          h,
          (fixedSatOrChroma / 100.0).clamp(0.0, 1.0),
          (l / 100.0).clamp(0.0, 1.0),
        ).toColor();
      case ColorSpaceMode.hsv:
        return HSVColor.fromAHSV(
          1.0,
          h,
          (fixedSatOrChroma / 100.0).clamp(0.0, 1.0),
          (l / 100.0).clamp(0.0, 1.0),
        ).toColor();
    }
  }

  @override
  bool shouldRepaint(covariant _HueLightnessMatrixPainter oldDelegate) {
    return oldDelegate.space != space ||
        oldDelegate.fixedSatOrChroma != fixedSatOrChroma ||
        oldDelegate.currentHue != currentHue ||
        oldDelegate.currentLightness != currentLightness ||
        oldDelegate.isDragging != isDragging;
  }
}

class _HorizontalChannelScrubber extends StatelessWidget {
  const _HorizontalChannelScrubber({
    required this.descriptor,
    required this.space,
    required this.activeColor,
    required this.onScrubStart,
    required this.onScrubUpdate,
    required this.onScrubEnd,
  });

  final ChannelDescriptor descriptor;
  final ColorSpaceMode space;
  final StudioColor activeColor;
  final VoidCallback onScrubStart;
  final ValueChanged<double> onScrubUpdate;
  final VoidCallback onScrubEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = List<Color>.generate(32, (i) {
      final norm = i / 31.0;
      final val = descriptor.min + norm * (descriptor.max - descriptor.min);
      return activeColor.sampleChannel(space, descriptor.index, val);
    });

    double valueForDx(double dx, double width) {
      if (width <= 0) return descriptor.value;
      final norm = (dx / width).clamp(0.0, 1.0);
      return descriptor.min + norm * (descriptor.max - descriptor.min);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              descriptor.name,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              descriptor.secondaryLabel != null
                  ? '${descriptor.formattedValue} (${descriptor.secondaryLabel})'
                  : descriptor.formattedValue,
              style: studioMonoStyle(
                context,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final thumbX =
                  (descriptor.normalized * (w - 18)).clamp(0.0, w - 18);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) {
                  onScrubStart();
                  onScrubUpdate(valueForDx(d.localPosition.dx, w));
                },
                onHorizontalDragUpdate: (d) =>
                    onScrubUpdate(valueForDx(d.localPosition.dx, w)),
                onHorizontalDragEnd: (_) => onScrubEnd(),
                onHorizontalDragCancel: onScrubEnd,
                onTapUp: (d) {
                  HapticFeedback.selectionClick();
                  onScrubStart();
                  onScrubUpdate(valueForDx(d.localPosition.dx, w));
                  onScrubEnd();
                },
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Positioned(
                      left: thumbX,
                      child: Container(
                        width: 18,
                        height: 28,
                        decoration: BoxDecoration(
                          color: activeColor.color,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: contrastingTextColor(activeColor.color),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
