import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/accessibility_utils.dart';
import '../models/color_spaces.dart';
import 'studio_theme.dart';

/// Moleskine Timepage-inspired kinetic fling reel that physically scrolls
/// perceptual pigment bands with momentum, trackpad scrubbing, and wave physics.
class SlidePickerColumn extends StatefulWidget {
  const SlidePickerColumn({
    super.key,
    required this.descriptor,
    required this.space,
    required this.activeColor,
    required this.isSteppedMode,
    required this.stepCount,
    required this.isFocused,
    required this.showContrastOverlay,
    required this.contrastRefColor,
    required this.onToggleFocus,
    required this.onScrubStart,
    required this.onScrubUpdate,
    required this.onScrubEnd,
    required this.onNudge,
  });

  final ChannelDescriptor descriptor;
  final ColorSpaceMode space;
  final StudioColor activeColor;
  final bool isSteppedMode;
  final int stepCount;
  final bool isFocused;
  final bool showContrastOverlay;
  final Color contrastRefColor;
  final VoidCallback onToggleFocus;
  final ValueChanged<double> onScrubStart;
  final ValueChanged<double> onScrubUpdate;
  final VoidCallback onScrubEnd;
  final ValueChanged<double> onNudge;

  @override
  State<SlidePickerColumn> createState() => _SlidePickerColumnState();
}

class _SlidePickerColumnState extends State<SlidePickerColumn>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  double? _hoverNormalizedValue;
  int? _lastHapticBucket;

  late final AnimationController _flingController;
  double _trackHeight = 400.0;
  double _dragAccumulatedVal = 0.0;
  double _flingStartVal = 0.0;
  double _flingTotalDelta = 0.0;
  double _flingCurrentVal = 0.0;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

  bool get _isHue => widget.descriptor.index == 0;

  /// Saturation/Chroma and Lightness/Tone grow upward (max at top, min at bottom);
  /// Hue runs circularly top-to-bottom through the centered focal lens.
  bool get _invertY => !_isHue;

  void _stopActiveFling({bool finalizeScrub = true}) {
    if (_flingController.isAnimating) {
      _flingController.stop();
      if (finalizeScrub) {
        widget.onScrubEnd();
      }
    }
  }

  void _onFlingTick() {
    final t = Curves.decelerate.transform(_flingController.value);
    final raw = _flingStartVal + _flingTotalDelta * t;
    final double val;
    if (_isHue) {
      val = ((raw % 360.0) + 360.0) % 360.0;
    } else {
      val = raw.clamp(widget.descriptor.min, widget.descriptor.max).toDouble();
    }
    _flingCurrentVal = val;
    _triggerStepHapticIfNeeded(val);
    widget.onScrubUpdate(val);
  }

  void _onFlingStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (widget.isSteppedMode) {
        final snapped = _nearestStepValue(_flingCurrentVal);
        widget.onScrubUpdate(snapped);
      }
      if (mounted) {
        setState(() {
          _isDragging = false;
          _lastHapticBucket = null;
        });
      }
      widget.onScrubEnd();
    }
  }

  double _nearestStepValue(double value) {
    final steps = _stepValues();
    if (steps.isEmpty) return value;
    var best = steps.first;
    var bestDiff = double.infinity;
    for (final s in steps) {
      final rawDiff = (s - value).abs();
      final diff = _isHue ? math.min(rawDiff, 360.0 - rawDiff) : rawDiff;
      if (diff < bestDiff) {
        bestDiff = diff;
        best = s;
      }
    }
    return best;
  }

  double _fractionForValue(double value) {
    if (_isHue) {
      return widget.isSteppedMode ? 0.5 : (value / 360.0).clamp(0.0, 1.0);
    }
    final span = widget.descriptor.max - widget.descriptor.min;
    if (span <= 0) return 0.5;
    final norm = ((value - widget.descriptor.min) / span).clamp(0.0, 1.0);
    return _invertY ? (1.0 - norm) : norm;
  }

  double _valueForLocalY(double localY, double height) {
    if (height <= 0) return widget.descriptor.value;
    final t = (localY / height).clamp(0.0, 1.0);
    if (_isHue) {
      if (!widget.isSteppedMode) {
        return (t * 360.0).clamp(0.0, 360.0);
      }
      return ((widget.descriptor.value + (t - 0.5) * 360.0) % 360.0 + 360.0) %
          360.0;
    }
    final norm = _invertY ? (1.0 - t) : t;
    final span = widget.descriptor.max - widget.descriptor.min;
    return (widget.descriptor.min + norm * span).clamp(
      widget.descriptor.min,
      widget.descriptor.max,
    );
  }

  List<double> _stepValues() {
    final count = widget.stepCount.clamp(4, 48);
    final min = widget.descriptor.min;
    final max = widget.descriptor.max;
    final span = max - min;

    if (_isHue) {
      final hueCount = switch (count) {
        10 => 12,
        20 => 24,
        _ => 36,
      };
      return List<double>.generate(
        hueCount,
        (i) => min + (i / hueCount) * span,
      );
    }

    if (widget.descriptor.index == 2 && min == 0 && max == 100) {
      return List<double>.generate(
        count - 1,
        (i) => max - ((i + 1) / count) * span,
      );
    }

    if (widget.descriptor.index == 1) {
      return List<double>.generate(
        count,
        (i) => max - (i / count) * span,
      );
    }

    return List<double>.generate(
      count + 1,
      (i) => max - (i / count) * span,
    );
  }

  /// Moleskine Timepage fisheye/wave weights: bands near the hovered pointer or
  /// active value swell organically while distant bands compress.
  List<int> _waveFlexes(List<double> steps) {
    final focusVal = _isDragging
        ? widget.descriptor.value
        : (_hoverNormalizedValue ?? widget.descriptor.value);
    final span = math.max(widget.descriptor.max - widget.descriptor.min, 1.0);
    final sigma = span * (steps.length > 20 ? 0.09 : 0.14);

    return List<int>.generate(steps.length, (i) {
      final rawDiff = (steps[i] - focusVal).abs();
      final diff = _isHue ? math.min(rawDiff, 360.0 - rawDiff) : rawDiff;
      final boost = math.exp(-(diff * diff) / (2.0 * sigma * sigma));
      return (75 + boost * 240).round();
    }, growable: false);
  }

  void _triggerStepHapticIfNeeded(double value) {
    final span = widget.descriptor.max - widget.descriptor.min;
    if (span <= 0) return;
    final norm = ((value - widget.descriptor.min) / span).clamp(0.0, 1.0);
    final bucket = (norm * widget.stepCount).round();
    if (_lastHapticBucket != null && _lastHapticBucket != bucket) {
      HapticFeedback.selectionClick();
    }
    _lastHapticBucket = bucket;
  }

  void _handleDragStart(DragStartDetails details) {
    _stopActiveFling();
    _dragAccumulatedVal = widget.descriptor.value;
    setState(() {
      _isDragging = true;
      _hoverNormalizedValue = null;
      _lastHapticBucket = null;
    });
    _triggerStepHapticIfNeeded(_dragAccumulatedVal);
    widget.onScrubStart(_dragAccumulatedVal);
  }

  void _handleDragUpdate(DragUpdateDetails details, double height) {
    final span = math.max(widget.descriptor.max - widget.descriptor.min, 1.0);
    final sensitivity = _isHue ? 0.85 : 0.75;
    final dragSign = (_isHue && !widget.isSteppedMode) ? 1.0 : -1.0;
    final deltaVal = dragSign *
        (details.delta.dy / math.max(height, 120.0)) *
        span *
        sensitivity;
    if (_isHue) {
      _dragAccumulatedVal = ((_dragAccumulatedVal + deltaVal) % 360.0 + 360.0) %
          360.0;
    } else {
      _dragAccumulatedVal = (_dragAccumulatedVal + deltaVal)
          .clamp(widget.descriptor.min, widget.descriptor.max)
          .toDouble();
    }
    _triggerStepHapticIfNeeded(_dragAccumulatedVal);
    widget.onScrubUpdate(_dragAccumulatedVal);
  }

  void _handleDragEnd(DragEndDetails details, double height) {
    if (!_isDragging) return;
    final vy = details.primaryVelocity ?? 0.0;
    if (vy.abs() > 50) {
      final span = math.max(widget.descriptor.max - widget.descriptor.min, 1.0);
      final dragSign = (_isHue && !widget.isSteppedMode) ? 1.0 : -1.0;
      _flingStartVal = _dragAccumulatedVal;
      _flingCurrentVal = _flingStartVal;
      _flingTotalDelta = dragSign * (vy / math.max(height, 120.0)) * span * 0.45;
      _flingController.forward(from: 0);
      return;
    }
    if (widget.isSteppedMode) {
      widget.onScrubUpdate(_nearestStepValue(_dragAccumulatedVal));
    }
    setState(() => _isDragging = false);
    _lastHapticBucket = null;
    widget.onScrubEnd();
  }

  void _handleDragCancel() {
    _stopActiveFling(finalizeScrub: false);
    if (_isDragging) {
      setState(() => _isDragging = false);
      _lastHapticBucket = null;
      widget.onScrubEnd();
    }
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    _stopActiveFling();
    final step = widget.space == ColorSpaceMode.oklch &&
            widget.descriptor.index == 1
        ? 2.0
        : (_isHue ? 4.0 : 2.5);
    final sign = event.scrollDelta.dy > 0 ? -step : step;
    final double next;
    if (_isHue) {
      next = ((widget.descriptor.value - sign) % 360.0 + 360.0) % 360.0;
    } else {
      next = (widget.descriptor.value + sign)
          .clamp(widget.descriptor.min, widget.descriptor.max)
          .toDouble();
    }
    HapticFeedback.selectionClick();
    widget.onNudge(next);
  }

  Future<void> _openExactValueDialog() async {
    final descriptor = widget.descriptor;
    final controller = TextEditingController(
      text: descriptor.value.round().toString(),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set ${descriptor.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText:
                'Value (${descriptor.min.round()}–${descriptor.max.round()}${descriptor.unit})',
            suffixText: descriptor.unit,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (raw) {
            final parsed = double.tryParse(raw.trim());
            if (parsed != null) {
              Navigator.of(ctx).pop(
                parsed.clamp(descriptor.min, descriptor.max).toDouble(),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed != null) {
                Navigator.of(ctx).pop(
                  parsed.clamp(descriptor.min, descriptor.max).toDouble(),
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      HapticFeedback.selectionClick();
      widget.onNudge(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final descriptor = widget.descriptor;
    final steps = _stepValues();
    final flexes = widget.isSteppedMode ? _waveFlexes(steps) : const <int>[];

    final swatchColor = _isHue
        ? widget.activeColor.color
        : widget.activeColor.sampleChannel(
            widget.space,
            descriptor.index,
            descriptor.value,
          );

    return Listener(
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          _handlePointerScroll(signal);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isDragging
                ? scheme.onSurface.withValues(alpha: 0.55)
                : scheme.outlineVariant.withValues(alpha: 0.25),
            width: _isDragging ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isDragging ? 0.16 : 0.06),
              blurRadius: _isDragging ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: _handleDragStart,
            onVerticalDragUpdate: (d) => _handleDragUpdate(d, _trackHeight),
            onVerticalDragEnd: (d) => _handleDragEnd(d, _trackHeight),
            onVerticalDragCancel: _handleDragCancel,
            child: Column(
              children: [
                // Unified paper editorial header
                _RibbonHeader(
                  descriptor: descriptor,
                  swatchColor: swatchColor,
                  onEditValue: _openExactValueDialog,
                ),
                // Interactive kinetic reel body
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final height = constraints.maxHeight;
                      if (height > 0) {
                        _trackHeight = height;
                      }
                      return MouseRegion(
                        cursor: _isDragging
                            ? SystemMouseCursors.grabbing
                            : SystemMouseCursors.grab,
                        onHover: (event) {
                          if (_isDragging || _isHue || height <= 0) return;
                          final hoverVal =
                              _valueForLocalY(event.localPosition.dy, height);
                          if (_hoverNormalizedValue == null ||
                              (hoverVal - _hoverNormalizedValue!).abs() > 0.6) {
                            setState(() {
                              _hoverNormalizedValue = hoverVal;
                            });
                          }
                        },
                        onExit: (_) => setState(() {
                          _hoverNormalizedValue = null;
                        }),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) {
                          _stopActiveFling();
                          final double val;
                          if (widget.isSteppedMode) {
                            if (_isHue) {
                              final bands = _computeHueReelBands(
                                descriptor.value,
                                steps.length,
                                height,
                              );
                              val = bands
                                  .firstWhere(
                                    (b) =>
                                        d.localPosition.dy >= b.topY &&
                                        d.localPosition.dy <= b.bottomY,
                                    orElse: () => bands[bands.length ~/ 2],
                                  )
                                  .angle;
                            } else {
                              final totalFlex = flexes.reduce((a, b) => a + b);
                              final targetFlex =
                                  (d.localPosition.dy / height)
                                      .clamp(0.0, 1.0) *
                                  totalFlex;
                              var acc = 0;
                              var tappedIdx = steps.length - 1;
                              for (int i = 0; i < flexes.length; i++) {
                                acc += flexes[i];
                                if (acc >= targetFlex) {
                                  tappedIdx = i;
                                  break;
                                }
                              }
                              val = steps[tappedIdx];
                            }
                          } else {
                            val = _valueForLocalY(d.localPosition.dy, height);
                          }
                          HapticFeedback.selectionClick();
                          widget.onNudge(val);
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (widget.isSteppedMode && _isHue)
                              _HueRotatingSteppedTrack(
                                totalSteps: steps.length,
                                descriptor: descriptor,
                                space: widget.space,
                                activeColor: widget.activeColor,
                                showContrastOverlay: widget.showContrastOverlay,
                                contrastRefColor: widget.contrastRefColor,
                              )
                            else if (widget.isSteppedMode)
                              _WaveSteppedTrack(
                                steps: steps,
                                flexes: flexes,
                                descriptor: descriptor,
                                space: widget.space,
                                activeColor: widget.activeColor,
                                showContrastOverlay: widget.showContrastOverlay,
                                contrastRefColor: widget.contrastRefColor,
                              )
                            else
                              _SmoothGradientTrack(
                                descriptor: descriptor,
                                space: widget.space,
                                activeColor: widget.activeColor,
                                invertY: _invertY,
                                isHue: _isHue,
                                showContrastOverlay: widget.showContrastOverlay,
                                contrastRefColor: widget.contrastRefColor,
                              ),
                            if (!widget.isSteppedMode || _isDragging)
                              _PaperLoupeIndicator(
                                fraction: _fractionForValue(descriptor.value),
                                descriptor: descriptor,
                                activeColor: widget.activeColor.color,
                                isDragging: _isDragging,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class _HueBand {
  const _HueBand({
    required this.angle,
    required this.topY,
    required this.bottomY,
    required this.distanceFromCenter,
  });

  final double angle;
  final double topY;
  final double bottomY;
  final double distanceFromCenter;
}

List<_HueBand> _computeHueReelBands(
  double activeHue,
  int totalSteps,
  double height,
) {
  if (height <= 0 || totalSteps <= 0) return const [];
  const visibleCount = 11;
  const halfVis = visibleCount / 2.0;
  final stepDeg = 360.0 / totalSteps;
  final continuousIdx = activeHue / stepDeg;
  final baseIdx = continuousIdx.floor();
  final frac = continuousIdx - baseIdx;

  double mapOffsetToY(double s) {
    final u = s / halfVis;
    const k = 0.65;
    final endVal = 1.0 + k * math.atan(1.6) / 1.6 * 1.15;
    final warped = u + k * math.atan(u * 1.6) / 1.6 * 1.15;
    final fracY = 0.5 + 0.5 * (warped / endVal);
    return fracY * height;
  }

  const half = visibleCount ~/ 2;
  final bands = <_HueBand>[];
  for (int slot = -half - 1; slot <= half + 1; slot++) {
    final sCenter = slot - frac;
    final topY = mapOffsetToY(sCenter - 0.5);
    final bottomY = mapOffsetToY(sCenter + 0.5);
    if (bottomY < -2 || topY > height + 2) continue;
    final rawAngle = (baseIdx + slot) * stepDeg;
    final angle = ((rawAngle % 360.0) + 360.0) % 360.0;
    bands.add(
      _HueBand(
        angle: angle,
        topY: topY,
        bottomY: bottomY,
        distanceFromCenter: sCenter.abs(),
      ),
    );
  }
  return bands;
}

class _HueRotatingSteppedTrack extends StatelessWidget {
  const _HueRotatingSteppedTrack({
    required this.totalSteps,
    required this.descriptor,
    required this.space,
    required this.activeColor,
    required this.showContrastOverlay,
    required this.contrastRefColor,
  });

  final int totalSteps;
  final ChannelDescriptor descriptor;
  final ColorSpaceMode space;
  final StudioColor activeColor;
  final bool showContrastOverlay;
  final Color contrastRefColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final bands = _computeHueReelBands(
          descriptor.value,
          totalSteps,
          height,
        );
        var selectedBandIdx = 0;
        var minDist = double.infinity;
        for (int i = 0; i < bands.length; i++) {
          if (bands[i].distanceFromCenter < minDist) {
            minDist = bands[i].distanceFromCenter;
            selectedBandIdx = i;
          }
        }
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (int i = 0; i < bands.length; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: bands[i].topY,
                  height: math.max(1.0, bands[i].bottomY - bands[i].topY + 0.6),
                  child: _WaveTile(
                    value: i == selectedBandIdx
                        ? descriptor.value
                        : bands[i].angle,
                    unit: descriptor.unit,
                    formattedLabel: i == selectedBandIdx
                        ? descriptor.formattedValue
                        : null,
                    color: i == selectedBandIdx
                        ? activeColor.color
                        : activeColor.sampleChannel(
                            space,
                            descriptor.index,
                            bands[i].angle,
                          ),
                    isSelected: i == selectedBandIdx,
                    showContrastOverlay: showContrastOverlay,
                    contrastRefColor: contrastRefColor,
                    compact: totalSteps >= 24,
                    showLabel:
                        bands[i].topY >= 2.0 &&
                        bands[i].bottomY <= height - 2.0 &&
                        (bands[i].bottomY - bands[i].topY) >= 20.0,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RibbonHeader extends StatelessWidget {
  const _RibbonHeader({
    required this.descriptor,
    required this.swatchColor,
    required this.onEditValue,
  });

  final ChannelDescriptor descriptor;
  final Color swatchColor;
  final VoidCallback onEditValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
      ),
      child: Tooltip(
        message: 'Double-tap for exact ${descriptor.name}',
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: onEditValue,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: swatchColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: scheme.onSurface.withValues(alpha: 0.14),
                            width: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          descriptor.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: studioMonoStyle(
                            context,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface.withValues(alpha: 0.58),
                          ).copyWith(letterSpacing: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          descriptor.formattedValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: studioDisplayStyle(
                            context,
                            fontSize: 42,
                            height: 0.94,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      if (descriptor.secondaryLabel != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          descriptor.secondaryLabel!,
                          style: studioMonoStyle(
                            context,
                            fontSize: 10,
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveSteppedTrack extends StatelessWidget {
  const _WaveSteppedTrack({
    required this.steps,
    required this.flexes,
    required this.descriptor,
    required this.space,
    required this.activeColor,
    required this.showContrastOverlay,
    required this.contrastRefColor,
  });

  final List<double> steps;
  final List<int> flexes;
  final ChannelDescriptor descriptor;
  final ColorSpaceMode space;
  final StudioColor activeColor;
  final bool showContrastOverlay;
  final Color contrastRefColor;

  @override
  Widget build(BuildContext context) {
    final activeVal = descriptor.value;
    var selectedIdx = 0;
    var bestDiff = double.infinity;
    for (int i = 0; i < steps.length; i++) {
      final rawDiff = (steps[i] - activeVal).abs();
      final diff = descriptor.index == 0
          ? math.min(rawDiff, 360.0 - rawDiff)
          : rawDiff;
      if (diff < bestDiff) {
        bestDiff = diff;
        selectedIdx = i;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < steps.length; i++)
          Expanded(
            flex: flexes[i],
            child: _WaveTile(
              value: i == selectedIdx ? activeVal : steps[i],
              unit: descriptor.unit,
              formattedLabel: i == selectedIdx
                  ? descriptor.formattedValue
                  : null,
              color: activeColor.sampleChannel(
                space,
                descriptor.index,
                i == selectedIdx ? activeVal : steps[i],
              ),
              isSelected: i == selectedIdx,
              showContrastOverlay: showContrastOverlay,
              contrastRefColor: contrastRefColor,
              compact: steps.length >= 24,
            ),
          ),
      ],
    );
  }
}

class _WaveTile extends StatelessWidget {
  const _WaveTile({
    required this.value,
    required this.unit,
    required this.color,
    required this.isSelected,
    required this.showContrastOverlay,
    required this.contrastRefColor,
    required this.compact,
    this.formattedLabel,
    this.showLabel = true,
  });

  final double value;
  final String unit;
  final String? formattedLabel;
  final Color color;
  final bool isSelected;
  final bool showContrastOverlay;
  final Color contrastRefColor;
  final bool compact;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final ink = contrastingTextColor(color);
    final ratio = showContrastOverlay
        ? wcagContrastRatio(color, contrastRefColor)
        : 0.0;

    final showAnyOverlay =
        (showLabel && isSelected) || showContrastOverlay;

    return ColoredBox(
      color: color,
      child: showAnyOverlay
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  if (showLabel && isSelected)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const Spacer(),
                  if (showContrastOverlay && !compact) ...[
                    Text(
                      '${ratio.toStringAsFixed(1)} ${wcagLevelLabel(ratio)}',
                      style: studioMonoStyle(
                        context,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: ink.withValues(alpha: ratio >= 4.5 ? 0.88 : 0.45),
                      ),
                    ),
                    if (showLabel && isSelected) const SizedBox(width: 8),
                  ] else if (showContrastOverlay && compact && ratio >= 4.5) ...[
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: ink.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (showLabel && isSelected) const SizedBox(width: 8),
                  ],
                  if (showLabel && isSelected)
                    Text(
                      formattedLabel ?? '${value.round()}$unit',
                      style: studioMonoStyle(
                        context,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ink.withValues(alpha: 0.96),
                      ),
                    ),
                ],
              ),
            )
          : const SizedBox.expand(),
    );
  }
}

class _SmoothGradientTrack extends StatelessWidget {
  const _SmoothGradientTrack({
    required this.descriptor,
    required this.space,
    required this.activeColor,
    required this.invertY,
    required this.isHue,
    required this.showContrastOverlay,
    required this.contrastRefColor,
  });

  final ChannelDescriptor descriptor;
  final ColorSpaceMode space;
  final StudioColor activeColor;
  final bool invertY;
  final bool isHue;
  final bool showContrastOverlay;
  final Color contrastRefColor;

  @override
  Widget build(BuildContext context) {
    const sampleCount = 64;
    final colors = List<Color>.generate(sampleCount, (i) {
      final t = i / (sampleCount - 1);
      final double value;
      if (isHue) {
        value = t * 360.0;
      } else {
        final norm = invertY ? (1.0 - t) : t;
        value = descriptor.min + norm * (descriptor.max - descriptor.min);
      }
      return activeColor.sampleChannel(space, descriptor.index, value);
    });

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: showContrastOverlay
          ? _ContrastSafeMarkers(
              descriptor: descriptor,
              space: space,
              activeColor: activeColor,
              invertY: invertY,
              contrastRefColor: contrastRefColor,
            )
          : const SizedBox.expand(),
    );
  }
}

class _ContrastSafeMarkers extends StatelessWidget {
  const _ContrastSafeMarkers({
    required this.descriptor,
    required this.space,
    required this.activeColor,
    required this.invertY,
    required this.contrastRefColor,
  });

  final ChannelDescriptor descriptor;
  final ColorSpaceMode space;
  final StudioColor activeColor;
  final bool invertY;
  final Color contrastRefColor;

  @override
  Widget build(BuildContext context) {
    const checks = 25;
    final passesAA = <double>[];
    for (int i = 0; i <= checks; i++) {
      final t = i / checks;
      final norm = invertY ? (1.0 - t) : t;
      final val = descriptor.min + norm * (descriptor.max - descriptor.min);
      final sampled = activeColor.sampleChannel(space, descriptor.index, val);
      final ratio = wcagContrastRatio(sampled, contrastRefColor);
      if (ratio >= 4.5) {
        passesAA.add(t);
      }
    }

    if (passesAA.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final top = passesAA.first * h;
        final bottom = passesAA.last * h;
        final barHeight = (bottom - top).clamp(4.0, h);
        return Stack(
          children: [
            Positioned(
              right: 7,
              top: top,
              height: barHeight,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 3),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaperLoupeIndicator extends StatelessWidget {
  const _PaperLoupeIndicator({
    required this.fraction,
    required this.descriptor,
    required this.activeColor,
    required this.isDragging,
  });

  final double fraction;
  final ChannelDescriptor descriptor;
  final Color activeColor;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    final ink = contrastingTextColor(activeColor);

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final pillHeight = isDragging ? 32.0 : 26.0;
        final rawTop = fraction * h - pillHeight / 2;
        final clampedTop =
            rawTop.clamp(4.0, (h - pillHeight - 4).clamp(4.0, h));

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: (fraction * h - 0.75).clamp(0.0, h - 1.5),
              child: Container(
                height: 1.5,
                color: ink.withValues(alpha: isDragging ? 0.55 : 0.25),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              top: clampedTop,
              height: pillHeight,
              child: AnimatedContainer(
                duration: isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 90),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: ink.withValues(alpha: isDragging ? 0.95 : 0.75),
                    width: isDragging ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDragging ? 0.30 : 0.16,
                      ),
                      blurRadius: isDragging ? 12 : 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      descriptor.formattedValue,
                      style: studioMonoStyle(
                        context,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
