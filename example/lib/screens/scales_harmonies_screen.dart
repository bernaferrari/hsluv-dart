import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../blocs/studio_cubit.dart';
import '../models/accessibility_utils.dart';
import '../models/color_spaces.dart';
import '../widgets/studio_theme.dart';

/// Pure visual Palette canvas: a tall 50–950 tonal scale ribbon, a 2×2 grid of
/// architectural harmony chord plates that pour into your paint wells, and a
/// full-width 1-tap export bar.
class ScalesHarmoniesScreen extends StatelessWidget {
  const ScalesHarmoniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudioCubit, StudioState>(
      builder: (context, state) {
        final cubit = context.read<StudioCubit>();
        final active = state.activeColor;
        final ramp = active.tonalRamp(state.activeSpace);
        final chords = _buildHarmonyChords(active, state.activeSpace);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 460;
            final ribbonHeight = isCompact ? 96.0 : 148.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: ribbonHeight,
                  child: _TonalRampRibbon(
                    ramp: ramp,
                    activeLightness:
                        active.channelsFor(state.activeSpace)[2].value,
                    onSelectStep: (color) {
                      HapticFeedback.selectionClick();
                      cubit.setActiveColor(StudioColor.fromColor(color));
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _HarmonyChordsGrid(
                    chords: chords,
                    onPourChord: (chord) {
                      HapticFeedback.lightImpact();
                      cubit.applyColorsToPalette(chord.colors);
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _ExportPillStrip(
                  palette: state.palette,
                  ramp: ramp,
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<_HarmonyChord> _buildHarmonyChords(
    StudioColor active,
    ColorSpaceMode space,
  ) {
    final channels = active.channelsFor(space);
    final baseHue = channels[0].value;
    final baseSat = math.max(active.hsluv.saturation, 58.0).clamp(0.0, 96.0);
    final baseLight = channels[2].value.clamp(28.0, 74.0);

    List<StudioColor> sampleChord(
      List<double> hueOffsets,
      List<double> lightOffsets,
      List<double> satScales,
    ) {
      return [
        for (int i = 0; i < 8; i++)
          StudioColor.fromColor(
            sampleAcrossSpace(
              space,
              hue: baseHue + hueOffsets[i],
              saturationPct: (baseSat * satScales[i]).clamp(14.0, 98.0),
              lightnessPct: (baseLight + lightOffsets[i]).clamp(12.0, 92.0),
            ),
          ),
      ];
    }

    return [
      _HarmonyChord(
        title: 'Analogous',
        angleLabel: '±22°',
        colors: sampleChord(
          const [0, 22, 44, -22, -44, 14, -14, 30],
          const [0, 8, -10, 10, -8, 20, -18, 26],
          const [1.0, 0.95, 0.92, 0.96, 0.88, 0.65, 0.78, 0.42],
        ),
      ),
      _HarmonyChord(
        title: 'Complementary',
        angleLabel: '180°',
        colors: sampleChord(
          const [0, 180, 14, 194, -14, 166, 0, 180],
          const [0, 0, 14, -12, -14, 16, 28, -22],
          const [1.0, 0.96, 0.85, 0.92, 0.88, 0.82, 0.42, 0.76],
        ),
      ),
      _HarmonyChord(
        title: 'Triadic',
        angleLabel: '120°',
        colors: sampleChord(
          const [0, 120, 240, 18, 138, 258, 0, 240],
          const [0, 4, -4, 16, -14, 14, 28, -24],
          const [1.0, 0.94, 0.94, 0.82, 0.85, 0.8, 0.4, 0.75],
        ),
      ),
      _HarmonyChord(
        title: 'Split',
        angleLabel: '150° · 210°',
        colors: sampleChord(
          const [0, 150, 210, 12, 162, 198, 0, 180],
          const [0, 6, -6, 16, -14, 14, 26, -24],
          const [1.0, 0.94, 0.94, 0.84, 0.86, 0.84, 0.42, 0.72],
        ),
      ),
    ];
  }
}

class _TonalRampRibbon extends StatelessWidget {
  const _TonalRampRibbon({
    required this.ramp,
    required this.activeLightness,
    required this.onSelectStep,
  });

  final List<({int token, Color color, double lightness})> ramp;
  final double activeLightness;
  final ValueChanged<Color> onSelectStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    var closestIdx = 0;
    var bestDiff = double.infinity;
    for (int i = 0; i < ramp.length; i++) {
      final diff = (ramp[i].lightness - activeLightness).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        closestIdx = i;
      }
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < ramp.length; i++)
            Expanded(
              child: _TonalBand(
                token: ramp[i].token,
                color: ramp[i].color,
                isClosest: i == closestIdx,
                onTap: () => onSelectStep(ramp[i].color),
              ),
            ),
        ],
      ),
    );
  }
}

class _TonalBand extends StatelessWidget {
  const _TonalBand({
    required this.token,
    required this.color,
    required this.isClosest,
    required this.onTap,
  });

  final int token;
  final Color color;
  final bool isClosest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = contrastingTextColor(color);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: ColoredBox(
          color: color,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isClosest) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 5),
                  ],
                  Text(
                    '$token',
                    maxLines: 1,
                    style: studioMonoStyle(
                      context,
                      fontSize: 10.5,
                      fontWeight: isClosest ? FontWeight.w700 : FontWeight.w600,
                      color: ink.withValues(alpha: isClosest ? 0.98 : 0.72),
                    ),
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

class _HarmonyChord {
  const _HarmonyChord({
    required this.title,
    required this.angleLabel,
    required this.colors,
  });

  final String title;
  final String angleLabel;
  final List<StudioColor> colors;
}

class _HarmonyChordsGrid extends StatelessWidget {
  const _HarmonyChordsGrid({
    required this.chords,
    required this.onPourChord,
  });

  final List<_HarmonyChord> chords;
  final ValueChanged<_HarmonyChord> onPourChord;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _HarmonyChordCard(
                  chord: chords[0],
                  onTap: () => onPourChord(chords[0]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HarmonyChordCard(
                  chord: chords[1],
                  onTap: () => onPourChord(chords[1]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _HarmonyChordCard(
                  chord: chords[2],
                  onTap: () => onPourChord(chords[2]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HarmonyChordCard(
                  chord: chords[3],
                  onTap: () => onPourChord(chords[3]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HarmonyChordCard extends StatelessWidget {
  const _HarmonyChordCard({
    required this.chord,
    required this.onTap,
  });

  final _HarmonyChord chord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visibleSwatches = chord.colors.take(5).toList(growable: false);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      chord.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: studioDisplayStyle(
                        context,
                        fontSize: 22,
                        height: 1.0,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    chord.angleLabel,
                    maxLines: 1,
                    style: studioMonoStyle(
                      context,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.52),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < visibleSwatches.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: visibleSwatches[i].color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportPillStrip extends StatelessWidget {
  const _ExportPillStrip({
    required this.palette,
    required this.ramp,
  });

  final List<StudioColor> palette;
  final List<({int token, Color color, double lightness})> ramp;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.copy_rounded,
        label: 'Copy HEX',
        onTap: () {
          final text = palette.map((c) => c.hex).join(', ');
          copyWithFeedback(context, text, label: 'Palette HEX');
        },
      ),
      (
        icon: Icons.code_rounded,
        label: 'Copy CSS oklch()',
        onTap: () {
          final lines = [
            for (int i = 0; i < palette.length; i++)
              '  --color-${i + 1}: ${palette[i].oklchDisplay};',
          ].join('\n');
          copyWithFeedback(
            context,
            ':root {\n$lines\n}',
            label: 'CSS oklch()',
          );
        },
      ),
      (
        icon: Icons.flutter_dash_rounded,
        label: 'Copy Flutter',
        onTap: () {
          final entries = [
            for (final c in palette) '  Color(0xFF${c.hex.substring(1)}),',
          ].join('\n');
          copyWithFeedback(
            context,
            'const studioPalette = <Color>[\n$entries\n];',
            label: 'Flutter Colors',
          );
        },
      ),
      (
        icon: Icons.palette_outlined,
        label: 'Copy Tailwind',
        onTap: () {
          final entries = [
            for (final s in ramp)
              "  '${s.token}': '${StudioColor.fromColor(s.color).hex}',",
          ].join('\n');
          copyWithFeedback(
            context,
            'primary: {\n$entries\n}',
            label: 'Tailwind Scale',
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ExportActionButton(
                      icon: actions[0].icon,
                      label: actions[0].label,
                      onTap: actions[0].onTap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ExportActionButton(
                      icon: actions[1].icon,
                      label: actions[1].label,
                      onTap: actions[1].onTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ExportActionButton(
                      icon: actions[2].icon,
                      label: actions[2].label,
                      onTap: actions[2].onTap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ExportActionButton(
                      icon: actions[3].icon,
                      label: actions[3].label,
                      onTap: actions[3].onTap,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _ExportActionButton(
                  icon: actions[i].icon,
                  label: actions[i].label,
                  onTap: actions[i].onTap,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ExportActionButton extends StatelessWidget {
  const _ExportActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF16181F) : const Color(0xFFECE9E1);
    final border = scheme.outlineVariant.withValues(alpha: isDark ? 0.24 : 0.38);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                        height: 1.15,
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
