import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluv/hsluv.dart';
import 'package:hsluv/hsluvcolor.dart';
import 'package:material_ui/material_ui.dart';

import '../blocs/studio_cubit.dart';
import '../models/accessibility_utils.dart';
import '../models/color_spaces.dart';
import 'studio_theme.dart';

/// Full-bleed Living Pigment Stage inspired by Moleskine Timepage and Paper by
/// FiftyThree: flooded with the active pigment, directly draggable and flingable
/// in 2D (hue × lightness) with editorial serif identity and a watercolor tray.
class ColorStagePanel extends StatefulWidget {
  const ColorStagePanel({
    super.key,
    this.isLandscapeSplit = true,
  });

  final bool isLandscapeSplit;

  @override
  State<ColorStagePanel> createState() => _ColorStagePanelState();
}

class _ColorStagePanelState extends State<ColorStagePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flingController;
  late final Animation<double> _flingCurve;

  bool _isDragging = false;
  bool _isScrubbing = false;
  double _dragHue = 0.0;
  double _dragLight = 50.0;
  double _flingStartHue = 0.0;
  double _flingStartLight = 50.0;
  double _flingDeltaHue = 0.0;
  double _flingDeltaLight = 0.0;
  ColorSpaceMode _scrubSpace = ColorSpaceMode.hsluv;

  @override
  void initState() {
    super.initState();
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

  void _onFlingTick() {
    if (!mounted || !_isScrubbing) return;
    final t = _flingCurve.value;
    final hue = _wrapHue(_flingStartHue + _flingDeltaHue * t);
    final light = (_flingStartLight + _flingDeltaLight * t).clamp(5.0, 95.0);
    _dragHue = hue;
    _dragLight = light;
    context.read<StudioCubit>().scrubTwoChannels(
          xChannel: 0,
          xValue: hue,
          yChannel: 2,
          yValue: light,
        );
  }

  void _finishScrub() {
    if (!_isScrubbing) return;
    _isScrubbing = false;
    if (mounted) {
      setState(() => _isDragging = false);
      context.read<StudioCubit>().endScrub();
    } else {
      _isDragging = false;
    }
  }

  void _handlePanStart(
    StudioColor active,
    ColorSpaceMode space,
  ) {
    _flingController.stop();
    final channels = active.channelsFor(space);
    _dragHue = channels[0].value;
    _dragLight = channels[2].value.clamp(5.0, 95.0);
    _scrubSpace = space;
    final cubit = context.read<StudioCubit>();
    if (!_isScrubbing) {
      _isScrubbing = true;
      cubit.beginScrub();
    }
    setState(() => _isDragging = true);
    HapticFeedback.selectionClick();
  }

  void _handlePanUpdate(
    DragUpdateDetails details,
    double width,
    double height,
  ) {
    if (!_isScrubbing) return;
    final safeW = math.max(width, 120.0);
    final safeH = math.max(height, 120.0);
    _dragHue = _wrapHue(_dragHue + (details.delta.dx / safeW) * 240.0);
    _dragLight =
        (_dragLight - (details.delta.dy / safeH) * 85.0).clamp(5.0, 95.0);
    context.read<StudioCubit>().scrubTwoChannels(
          xChannel: 0,
          xValue: _dragHue,
          yChannel: 2,
          yValue: _dragLight,
        );
  }

  void _handlePanEnd(
    DragEndDetails details,
    double width,
    double height,
  ) {
    if (!_isScrubbing) return;
    final v = details.velocity.pixelsPerSecond;
    final speed = v.distance;
    if (speed > 60.0) {
      final safeW = math.max(width, 120.0);
      final safeH = math.max(height, 120.0);
      _flingStartHue = _dragHue;
      _flingStartLight = _dragLight;
      _flingDeltaHue = (v.dx / safeW) * 240.0 * 0.42;
      _flingDeltaLight = -(v.dy / safeH) * 85.0 * 0.42;
      if (_flingDeltaHue.abs() > 0.5 || _flingDeltaLight.abs() > 0.5) {
        _flingController.forward(from: 0.0);
        return;
      }
    }
    _finishScrub();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscapeSplit = widget.isLandscapeSplit;
    return BlocBuilder<StudioCubit, StudioState>(
      builder: (context, state) {
        final cubit = context.read<StudioCubit>();
        final active = state.activeColor;
        final ink = contrastingTextColor(active.color);
        final nearestName = ColorNameLookup.nearestNameSync(active.color);
        final cieLStar = Hsluv.yToL(active.color.computeLuminance()).round();

        final channels = active.channelsFor(state.activeSpace);
        final displayHue =
            (_isScrubbing && _scrubSpace == state.activeSpace)
                ? _dragHue
                : channels[0].value;
        final displayLight =
            (_isScrubbing && _scrubSpace == state.activeSpace)
                ? _dragLight
                : channels[2].value;
        final normX = (displayHue / 360.0).clamp(0.0, 1.0);
        final normY =
            (1.0 - ((displayLight - 5.0) / 90.0)).clamp(0.0, 1.0);

        final topGlow = HSLuvColor.fromHSL(
          active.hsluv.hue,
          active.hsluv.saturation,
          (active.hsluv.lightness + 7.0).clamp(0.0, 100.0),
        ).toColor();
        final bottomShade = HSLuvColor.fromHSL(
          (active.hsluv.hue + 6.0) % 360.0,
          active.hsluv.saturation,
          (active.hsluv.lightness - 7.0).clamp(0.0, 100.0),
        ).toColor();
        final bloomColor = HSLuvColor.fromHSL(
          active.hsluv.hue,
          (active.hsluv.saturation * 0.85).clamp(0.0, 100.0),
          (active.hsluv.lightness + 18.0).clamp(15.0, 98.0),
        ).toColor();

        const activeSpaceOptions = [
          ColorSpaceMode.hsluv,
          ColorSpaceMode.oklch,
          ColorSpaceMode.hct,
        ];
        final selectorValue = activeSpaceOptions.contains(state.activeSpace)
            ? state.activeSpace
            : ColorSpaceMode.hsluv;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isLandscapeSplit ? 30 : 24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [topGlow, active.color, bottomShade],
            ),
            border: Border.all(
              color: ink.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: active.color.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Organic radial light bloom tracking the active hue & lightness
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(
                          (normX * 2.0 - 1.0) * 0.72,
                          (normY * 2.0 - 1.0) * 0.56,
                        ),
                        radius: isLandscapeSplit ? 0.85 : 1.05,
                        colors: [
                          bloomColor.withValues(alpha: _isDragging ? 0.36 : 0.24),
                          active.color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isLandscapeSplit ? 22 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Clean floating header: 3 perceptual space pills + essential icons
                    Row(
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: StudioPillSelector<ColorSpaceMode>(
                              compact: true,
                              canvasInk: ink,
                              value: selectorValue,
                              options: const [
                                StudioPillOption(
                                  value: ColorSpaceMode.hsluv,
                                  label: 'HSLuv',
                                ),
                                StudioPillOption(
                                  value: ColorSpaceMode.oklch,
                                  label: 'OKLCH',
                                ),
                                StudioPillOption(
                                  value: ColorSpaceMode.hct,
                                  label: 'HCT',
                                ),
                              ],
                              onChanged: cubit.setSpaceMode,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StageIconButton(
                          icon: Icons.auto_awesome_rounded,
                          tooltip: 'Shuffle unlocked harmonies (Space)',
                          ink: ink,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            cubit.shuffleUnlockedColors();
                          },
                        ),
                        if (state.canUndo) ...[
                          const SizedBox(width: 6),
                          _StageIconButton(
                            icon: Icons.undo_rounded,
                            tooltip: 'Undo (Cmd/Ctrl+Z)',
                            ink: ink,
                            onTap: cubit.undo,
                          ),
                        ],
                        const SizedBox(width: 6),
                        _StageIconButton(
                          icon: state.themeMode == ThemeMode.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          tooltip: state.themeMode == ThemeMode.dark
                              ? 'Warm Paper Mode'
                              : 'Obsidian Dark Mode',
                          ink: ink,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            cubit.toggleThemeMode();
                          },
                        ),
                      ],
                    ),

                    if (isLandscapeSplit)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;
                            const pad = 16.0;
                            final ringSize = _isDragging ? 22.0 : 18.0;
                            final usableW = math.max(1.0, w - pad * 2);
                            final usableH = math.max(1.0, h - pad * 2);
                            final cx = pad + normX * usableW;
                            final cy = pad + normY * usableH;

                            return MouseRegion(
                              cursor: _isDragging
                                  ? SystemMouseCursors.grabbing
                                  : SystemMouseCursors.grab,
                              child: GestureDetector(
                                key: const ValueKey('stage_2d_canvas'),
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (_) => _handlePanStart(
                                  active,
                                  state.activeSpace,
                                ),
                                onPanUpdate: (details) =>
                                    _handlePanUpdate(details, w, h),
                                onPanEnd: (details) =>
                                    _handlePanEnd(details, w, h),
                                onPanCancel: _finishScrub,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Positioned(
                                      left: cx - ringSize * 0.5,
                                      top: cy - ringSize * 0.5,
                                      child: IgnorePointer(
                                        child: AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          opacity: _isDragging ? 1.0 : 0.0,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 140,
                                            ),
                                            width: ringSize,
                                            height: ringSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _isDragging
                                                  ? ink.withValues(alpha: 0.14)
                                                  : Colors.transparent,
                                              border: Border.all(
                                                color: ink.withValues(
                                                  alpha: 0.88,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const SizedBox(height: 12),

                    // Editorial serif specimen identity
                    Text(
                      nearestName ?? 'Pure Specimen',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: studioDisplayStyle(
                        context,
                        fontSize: isLandscapeSplit ? 52 : 36,
                        height: 0.96,
                        letterSpacing: -0.6,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Inline HEX copy pill + custom input + live perceptual readout
                    Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => copyWithFeedback(
                              context,
                              active.hex,
                              label: 'HEX',
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: ink.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    active.hex,
                                    style: studioMonoStyle(
                                      context,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: ink,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 13,
                                    color: ink.withValues(alpha: 0.65),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StageIconButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'Enter custom HEX, rgb(), or oklch()',
                          ink: ink,
                          onTap: () => _openColorInputDialog(context, active),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _liveCoordSummary(
                              active,
                              state.activeSpace,
                              cieLStar,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: studioMonoStyle(
                              context,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: ink.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isLandscapeSplit ? 16 : 12),

                    // Swipeable Paper-by-FiftyThree watercolor wells
                    _WatercolorWellTray(
                      palette: state.palette,
                      selectedIndex: state.selectedIndex,
                      lockedSlots: state.lockedSlots,
                      stageInk: ink,
                      onSelect: (idx) {
                        HapticFeedback.selectionClick();
                        cubit.selectSlot(idx);
                      },
                      onToggleLock: (idx) {
                        HapticFeedback.mediumImpact();
                        cubit.toggleLockSlot(idx);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _liveCoordSummary(
    StudioColor active,
    ColorSpaceMode space,
    int cieLStar,
  ) {
    switch (space) {
      case ColorSpaceMode.oklch:
        return 'L ${active.oklch.lightness.round()}% · C ${active.oklch.chroma.toStringAsFixed(2)} · ${active.oklch.hue.round()}°';
      case ColorSpaceMode.hct:
        return 'H ${active.hctHue.round()}° · C ${active.hctChroma.round()} · T ${active.hctTone.round()}';
      case ColorSpaceMode.hsluv:
      case ColorSpaceMode.hsl:
      case ColorSpaceMode.hsv:
        return '${active.hsluv.hue.round()}° · ${active.hsluv.saturation.round()}% · L* $cieLStar';
    }
  }

  Future<void> _openColorInputDialog(
    BuildContext context,
    StudioColor current,
  ) async {
    final cubit = context.read<StudioCubit>();
    final controller = TextEditingController(text: current.hex);
    Color? preview = current.color;

    final result = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Color Specimen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 64,
                    decoration: BoxDecoration(
                      color: preview ?? current.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      preview == null
                          ? 'Invalid format'
                          : StudioColor.fromColor(preview!).hex,
                      style: studioMonoStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: contrastingTextColor(preview ?? current.color),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: studioMonoStyle(context, fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: 'HEX, rgb(...), or oklch(...)',
                      hintText: '#3B82F6 or oklch(62% 0.19 259)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        preview = parseColorInput(value);
                      });
                    },
                    onSubmitted: (_) {
                      if (preview != null) {
                        Navigator.of(dialogContext).pop(preview);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: preview == null
                      ? null
                      : () => Navigator.of(dialogContext).pop(preview),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (result != null) {
      cubit.setActiveColor(StudioColor.fromColor(result));
    }
  }
}

class _StageIconButton extends StatelessWidget {
  const _StageIconButton({
    required this.icon,
    required this.tooltip,
    required this.ink,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ink.withValues(alpha: enabled ? 0.12 : 0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 15,
              color: ink.withValues(alpha: enabled ? 0.92 : 0.30),
            ),
          ),
        ),
      ),
    );
  }
}

class _WatercolorWellTray extends StatelessWidget {
  const _WatercolorWellTray({
    required this.palette,
    required this.selectedIndex,
    required this.lockedSlots,
    required this.stageInk,
    required this.onSelect,
    required this.onToggleLock,
  });

  final List<StudioColor> palette;
  final int selectedIndex;
  final Set<int> lockedSlots;
  final Color stageInk;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onToggleLock;

  void _scrubTray(double localDx, double totalWidth) {
    if (totalWidth <= 0 || palette.isEmpty) return;
    final t = (localDx / totalWidth).clamp(0.0, 0.9999);
    final idx = (t * palette.length).floor();
    if (idx >= 0 && idx < palette.length && idx != selectedIndex) {
      onSelect(idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: stageInk.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stageInk.withValues(alpha: 0.14)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) => _scrubTray(d.localPosition.dx, maxW),
            onHorizontalDragUpdate: (d) => _scrubTray(d.localPosition.dx, maxW),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < palette.length; i++)
                  _PigmentWell(
                    color: palette[i].color,
                    isSelected: i == selectedIndex,
                    isLocked: lockedSlots.contains(i),
                    tooltip:
                        '${palette[i].hex} · Slide or tap · Hold to ${lockedSlots.contains(i) ? 'unlock' : 'lock'}',
                    onTap: () => onSelect(i),
                    onLongPress: () => onToggleLock(i),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PigmentWell extends StatelessWidget {
  const _PigmentWell({
    required this.color,
    required this.isSelected,
    required this.isLocked,
    required this.tooltip,
    required this.onTap,
    required this.onLongPress,
  });

  final Color color;
  final bool isSelected;
  final bool isLocked;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final wellInk = contrastingTextColor(color);
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutBack,
            transform: Matrix4.translationValues(0, isSelected ? -5 : 0, 0),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: isSelected ? 0.92 : 0.72),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.28 : 0.16,
                  ),
                  blurRadius: isSelected ? 8 : 5,
                  offset: Offset(0, isSelected ? 3 : 2),
                ),
              ],
            ),
            child: isLocked
                ? Icon(
                    Icons.lock_rounded,
                    size: 11,
                    color: wellInk.withValues(alpha: 0.9),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
