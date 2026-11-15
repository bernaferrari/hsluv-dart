import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluv/hsluv.dart';
import 'package:material_ui/material_ui.dart';

import '../blocs/studio_cubit.dart';
import '../models/accessibility_utils.dart';
import '../models/color_spaces.dart';
import '../widgets/studio_theme.dart';

/// Pure visual kinetic perceptual comparison across HSLuv, OKLCH, HCT, and HSL.
/// Drag or fling horizontally to spin all four spectrums with the live active
/// hue centered across every ribbon, or scrub vertically to shift lightness.
class SpaceComparisonScreen extends StatefulWidget {
  const SpaceComparisonScreen({super.key});

  @override
  State<SpaceComparisonScreen> createState() => _SpaceComparisonScreenState();
}

class _SpaceComparisonScreenState extends State<SpaceComparisonScreen>
    with SingleTickerProviderStateMixin {
  static const _modes = <ColorSpaceMode>[
    ColorSpaceMode.hsluv,
    ColorSpaceMode.oklch,
    ColorSpaceMode.hct,
    ColorSpaceMode.hsl,
  ];
  static const int _swatchCount = 15;
  static const int _centerIndex = 7;

  late final AnimationController _flingController;
  late final Animation<double> _flingCurve;

  late double _huePhase;
  late double _sharedLightness;
  StudioColor? _lastObservedColor;

  bool _isDragging = false;
  bool _isScrubbing = false;
  double _flingStartHue = 0.0;
  double _flingStartLight = 60.0;
  double _flingDeltaHue = 0.0;
  double _flingDeltaLight = 0.0;

  @override
  void initState() {
    super.initState();
    final state = context.read<StudioCubit>().state;
    final channels = state.activeColor.channelsFor(state.activeSpace);
    _huePhase = channels[0].value;
    _sharedLightness = channels[2].value.clamp(15.0, 90.0);
    _lastObservedColor = state.activeColor;

    _flingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _flingCurve = CurvedAnimation(
      parent: _flingController,
      curve: Curves.decelerate,
    )..addListener(_onFlingTick);
    _flingController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _finishScrub();
      }
    });
  }

  @override
  void dispose() {
    _flingController.dispose();
    super.dispose();
  }

  double _wrapHue(double hue) {
    final h = hue % 360.0;
    return h < 0 ? h + 360.0 : h;
  }

  void _pushScrubToCubit() {
    context.read<StudioCubit>().scrubTwoChannels(
          xChannel: 0,
          xValue: _huePhase,
          yChannel: 2,
          yValue: _sharedLightness,
        );
  }

  void _onFlingTick() {
    if (!mounted || !_isScrubbing) return;
    final t = _flingCurve.value;
    setState(() {
      _huePhase = _wrapHue(_flingStartHue + _flingDeltaHue * t);
      _sharedLightness = (_flingStartLight + _flingDeltaLight * t).clamp(
        15.0,
        90.0,
      );
    });
    _pushScrubToCubit();
  }

  void _finishScrub() {
    if (!_isScrubbing) return;
    _isScrubbing = false;
    if (mounted) {
      final cubit = context.read<StudioCubit>();
      _lastObservedColor = cubit.state.activeColor;
      setState(() => _isDragging = false);
      cubit.endScrub();
    } else {
      _isDragging = false;
    }
  }

  void _handlePanStart() {
    _flingController.stop();
    final cubit = context.read<StudioCubit>();
    if (!_isScrubbing) {
      _isScrubbing = true;
      cubit.beginScrub();
    }
    setState(() => _isDragging = true);
    HapticFeedback.selectionClick();
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (!_isScrubbing) return;
    final safeW = size.width < 160.0 ? 160.0 : size.width;
    final safeH = size.height < 160.0 ? 160.0 : size.height;
    setState(() {
      _huePhase = _wrapHue(_huePhase - (details.delta.dx / safeW) * 240.0);
      _sharedLightness =
          (_sharedLightness - (details.delta.dy / safeH) * 65.0)
              .clamp(15.0, 90.0);
    });
    _pushScrubToCubit();
  }

  void _handlePanEnd(DragEndDetails details, Size size) {
    if (!_isScrubbing) return;
    final v = details.velocity.pixelsPerSecond;
    final speed = v.distance;
    if (speed > 50.0) {
      final safeW = size.width < 160.0 ? 160.0 : size.width;
      final safeH = size.height < 160.0 ? 160.0 : size.height;
      _flingStartHue = _huePhase;
      _flingStartLight = _sharedLightness;
      _flingDeltaHue = -(v.dx / safeW) * 240.0 * 0.45;
      _flingDeltaLight = -(v.dy / safeH) * 65.0 * 0.45;
      if (_flingDeltaHue.abs() > 0.5 || _flingDeltaLight.abs() > 0.5) {
        _flingController.forward(from: 0.0);
        return;
      }
    }
    _finishScrub();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StudioCubit, StudioState>(
      listenWhen: (prev, next) => prev.activeColor != next.activeColor,
      listener: (context, state) {
        if (!_isScrubbing &&
            !_isDragging &&
            !_flingController.isAnimating &&
            state.activeColor != _lastObservedColor) {
          final channels = state.activeColor.channelsFor(state.activeSpace);
          setState(() {
            _lastObservedColor = state.activeColor;
            _huePhase = channels[0].value;
            _sharedLightness = channels[2].value.clamp(15.0, 90.0);
          });
        }
      },
      child: BlocBuilder<StudioCubit, StudioState>(
        builder: (context, state) {
          final cubit = context.read<StudioCubit>();
          final satPct = state.activeColor.hsluv.saturation.clamp(45.0, 96.0);

          return LayoutBuilder(
            builder: (context, constraints) {
              final areaSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return MouseRegion(
                cursor: _isDragging
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab,
                child: GestureDetector(
                  key: const ValueKey<String>('spectrum_gesture_canvas'),
                  behavior: HitTestBehavior.translucent,
                  onPanStart: (_) => _handlePanStart(),
                  onPanUpdate: (d) => _handlePanUpdate(d, areaSize),
                  onPanEnd: (d) => _handlePanEnd(d, areaSize),
                  onPanCancel: _finishScrub,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int r = 0; r < _modes.length; r++) ...[
                        if (r > 0) const SizedBox(height: 12),
                        Expanded(
                          child: _SpectrumRibbon(
                            mode: _modes[r],
                            huePhase: _huePhase,
                            saturationPct: satPct,
                            lightnessPct: _sharedLightness,
                            swatchCount: _swatchCount,
                            centerIndex: _centerIndex,
                            onPickSwatch: (hue, color) {
                              HapticFeedback.selectionClick();
                              final studioColor = StudioColor.fromColor(color);
                              setState(() {
                                _huePhase = hue;
                                _lastObservedColor = studioColor;
                              });
                              cubit.setActiveColor(studioColor);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SpectrumRibbon extends StatelessWidget {
  const _SpectrumRibbon({
    required this.mode,
    required this.huePhase,
    required this.saturationPct,
    required this.lightnessPct,
    required this.swatchCount,
    required this.centerIndex,
    required this.onPickSwatch,
  });

  final ColorSpaceMode mode;
  final double huePhase;
  final double saturationPct;
  final double lightnessPct;
  final int swatchCount;
  final int centerIndex;
  final void Function(double hue, Color color) onPickSwatch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stepDeg = 360.0 / swatchCount;
    final swatchHues = List<double>.generate(swatchCount, (i) {
      return ((huePhase + (i - centerIndex) * stepDeg) % 360.0 + 360.0) % 360.0;
    });
    final swatches = [
      for (final hue in swatchHues)
        sampleAcrossSpace(
          mode,
          hue: hue,
          saturationPct: saturationPct,
          lightnessPct: lightnessPct,
        ),
    ];

    var minL = 100;
    var maxL = 0;
    for (final c in swatches) {
      final lStar = Hsluv.yToL(c.computeLuminance()).round();
      if (lStar < minL) minL = lStar;
      if (lStar > maxL) maxL = lStar;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < swatches.length; i++)
                Expanded(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onPickSwatch(swatchHues[i], swatches[i]),
                      child: ColoredBox(
                        color: swatches[i],
                        child: i == centerIndex
                            ? Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _centerDot(swatches[i], isTop: true),
                                  _centerDot(swatches[i], isTop: false),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  mode.label,
                  style: studioDisplayStyle(
                    context,
                    fontSize: 22,
                    height: 1.0,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'L* $minL–$maxL',
                  style: studioMonoStyle(
                    context,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _centerDot(Color bg, {required bool isTop}) {
    return Container(
      margin: EdgeInsets.only(
        top: isTop ? 9 : 0,
        bottom: isTop ? 0 : 9,
      ),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: contrastingTextColor(bg),
        shape: BoxShape.circle,
      ),
    );
  }
}
