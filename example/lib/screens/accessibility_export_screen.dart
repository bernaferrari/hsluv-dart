import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../blocs/studio_cubit.dart';
import '../models/accessibility_utils.dart';
import '../models/color_spaces.dart';
import '../widgets/studio_theme.dart';

enum _ExportFormat { css4, tailwind, flutter, designTokens }

/// Combined WCAG 2.1 + APCA contrast analyzer, CVD simulator,
/// multi-format code/token exporter, and specification links.
class AccessibilityExportScreen extends StatefulWidget {
  const AccessibilityExportScreen({super.key});

  @override
  State<AccessibilityExportScreen> createState() =>
      _AccessibilityExportScreenState();
}

class _AccessibilityExportScreenState extends State<AccessibilityExportScreen> {
  int _refSlotIndex = -1; // -1 = White, -2 = Obsidian (#121318), 0..7 = slot
  bool _invertPreview = false;
  CvdType _selectedCvd = CvdType.deuteranopia;
  _ExportFormat _exportFormat = _ExportFormat.css4;

  Color _resolveReferenceColor(List<StudioColor> palette) {
    if (_refSlotIndex == -1) return Colors.white;
    if (_refSlotIndex == -2) return const Color(0xFF121318);
    if (_refSlotIndex >= 0 && _refSlotIndex < palette.length) {
      return palette[_refSlotIndex].color;
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudioCubit, StudioState>(
      builder: (context, state) {
        final cubit = context.read<StudioCubit>();
        final active = state.activeColor;
        final refColor = _resolveReferenceColor(state.palette);
        final fg = _invertPreview ? refColor : active.color;
        final bg = _invertPreview ? active.color : refColor;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContrastInspectorCard(
                activeColor: active,
                palette: state.palette,
                refSlotIndex: _refSlotIndex,
                invertPreview: _invertPreview,
                fgColor: fg,
                bgColor: bg,
                refColor: refColor,
                onRefChanged: (idx) => setState(() => _refSlotIndex = idx),
                onToggleInvert: () =>
                    setState(() => _invertPreview = !_invertPreview),
                onFixContrast: (target) {
                  final ok = cubit.fixActiveColorContrast(
                    target,
                    against: refColor,
                  );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not reach that ratio at this hue against this background',
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _CvdSimulatorCard(
                palette: state.palette,
                activeColor: active.color,
                selectedCvd: _selectedCvd,
                onCvdChanged: (type) => setState(() => _selectedCvd = type),
              ),
              const SizedBox(height: 12),
              _ExportHubCard(
                state: state,
                format: _exportFormat,
                onFormatChanged: (fmt) => setState(() => _exportFormat = fmt),
              ),
              const SizedBox(height: 12),
              const _AboutLinksCard(),
            ],
          ),
        );
      },
    );
  }
}

class _ContrastInspectorCard extends StatelessWidget {
  const _ContrastInspectorCard({
    required this.activeColor,
    required this.palette,
    required this.refSlotIndex,
    required this.invertPreview,
    required this.fgColor,
    required this.bgColor,
    required this.refColor,
    required this.onRefChanged,
    required this.onToggleInvert,
    required this.onFixContrast,
  });

  final StudioColor activeColor;
  final List<StudioColor> palette;
  final int refSlotIndex;
  final bool invertPreview;
  final Color fgColor;
  final Color bgColor;
  final Color refColor;
  final ValueChanged<int> onRefChanged;
  final VoidCallback onToggleInvert;
  final ValueChanged<double> onFixContrast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final ratio = wcagContrastRatio(fgColor, bgColor);
    final lc = apcaContrast(fgColor, bgColor).abs();
    final passAA = ratio >= 4.5;
    final passAAA = ratio >= 7.0;
    final passAALarge = ratio >= 3.0;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WCAG 2.1 & APCA Contrast Lab',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Test readability against surfaces or palette pairs, then snap lightness in 1 tap',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ActionChip(
                  avatar: const Icon(Icons.swap_vert_rounded, size: 16),
                  label: Text(invertPreview ? 'Fg / Bg Swapped' : 'Swap Fg / Bg'),
                  onPressed: onToggleInvert,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('White #FFF'),
                    selected: refSlotIndex == -1,
                    onSelected: (_) => onRefChanged(-1),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Dark #121318'),
                    selected: refSlotIndex == -2,
                    onSelected: (_) => onRefChanged(-2),
                  ),
                  const SizedBox(width: 6),
                  for (int i = 0; i < palette.length; i++) ...[
                    ChoiceChip(
                      avatar: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: palette[i].color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      label: Text('S${i + 1}'),
                      selected: refSlotIndex == i,
                      onSelected: (_) => onRefChanged(i),
                    ),
                    const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Large Heading Sample (20sp Bold)',
                    style: textTheme.titleLarge?.copyWith(
                      color: fgColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Body copy readability check in HSLuv, OKLCH, and HCT. '
                    'Perceptual lightness (L*) makes predicting contrast ratios reliable across every hue.',
                    style: textTheme.bodyMedium?.copyWith(color: fgColor),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ContrastScorePill(
                        label: 'WCAG',
                        value: '${ratio.toStringAsFixed(2)}:1',
                        pass: passAALarge,
                      ),
                      _ContrastScorePill(
                        label: 'AA Normal (4.5)',
                        value: passAA ? 'PASS' : 'FAIL',
                        pass: passAA,
                      ),
                      _ContrastScorePill(
                        label: 'AAA (7.0)',
                        value: passAAA ? 'PASS' : 'FAIL',
                        pass: passAAA,
                      ),
                      _ContrastScorePill(
                        label: 'APCA',
                        value: 'Lc ${lc.round()}',
                        pass: lc >= 60,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => onFixContrast(4.5),
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                  label: const Text('Snap Lightness -> AA (4.5:1)'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onFixContrast(7.0),
                  icon: const Icon(Icons.verified_outlined, size: 16),
                  label: const Text('Snap -> AAA (7.0:1)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContrastScorePill extends StatelessWidget {
  const _ContrastScorePill({
    required this.label,
    required this.value,
    required this.pass,
  });

  final String label;
  final String value;
  final bool pass;

  @override
  Widget build(BuildContext context) {
    final badgeColor = pass
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            pass ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 13,
            color: badgeColor,
          ),
          const SizedBox(width: 5),
          Text(
            '$label · $value',
            style: studioMonoStyle(
              context,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CvdSimulatorCard extends StatelessWidget {
  const _CvdSimulatorCard({
    required this.palette,
    required this.activeColor,
    required this.selectedCvd,
    required this.onCvdChanged,
  });

  final List<StudioColor> palette;
  final Color activeColor;
  final CvdType selectedCvd;
  final ValueChanged<CvdType> onCvdChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Color Vision Deficiency (CVD) Simulator',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Verify your entire 8-color palette remains distinguishable across color vision profiles',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final type in CvdType.values.where(
                  (t) => t != CvdType.normal,
                ))
                  ChoiceChip(
                    label: Text(type.label),
                    visualDensity: VisualDensity.compact,
                    selected: selectedCvd == type,
                    onSelected: (_) => onCvdChanged(type),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${selectedCvd.label}: ${selectedCvd.description}',
              style: textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _PaletteComparisonStrip(
              title: 'Original Vision',
              colors: palette.map((s) => s.color).toList(),
            ),
            const SizedBox(height: 8),
            _PaletteComparisonStrip(
              title: '${selectedCvd.label} Simulation',
              colors: palette
                  .map((s) => selectedCvd.simulate(s.color))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteComparisonStrip extends StatelessWidget {
  const _PaletteComparisonStrip({
    required this.title,
    required this.colors,
  });

  final String title;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 42,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < colors.length; i++)
                  Expanded(
                    child: ColoredBox(
                      color: colors[i],
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: studioMonoStyle(
                            context,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: contrastingTextColor(colors[i])
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExportHubCard extends StatelessWidget {
  const _ExportHubCard({
    required this.state,
    required this.format,
    required this.onFormatChanged,
  });

  final StudioState state;
  final _ExportFormat format;
  final ValueChanged<_ExportFormat> onFormatChanged;

  String _generateCode() {
    final palette = state.palette;
    final scale = state.activeColor.tonalRamp(
      state.activeSpace.isPerceptual ? state.activeSpace : ColorSpaceMode.oklch,
    );

    switch (format) {
      case _ExportFormat.css4:
        final buf = StringBuffer(':root {\n');
        for (int i = 0; i < palette.length; i++) {
          final c = palette[i];
          buf.writeln(
            '  --palette-${i + 1}: ${c.oklch.toCssString()}; /* ${c.hex} */',
          );
        }
        buf.writeln('');
        for (final stop in scale) {
          final ok = OklchColor.fromColor(stop.color);
          buf.writeln('  --brand-${stop.token}: ${ok.toCssString()};');
        }
        buf.write('}');
        return buf.toString();

      case _ExportFormat.tailwind:
        final buf = StringBuffer('@theme {\n');
        for (int i = 0; i < palette.length; i++) {
          buf.writeln(
            '  --color-slot-${i + 1}: ${palette[i].oklch.toCssString()};',
          );
        }
        for (final stop in scale) {
          buf.writeln(
            '  --color-brand-${stop.token}: ${OklchColor.fromColor(stop.color).toCssString()};',
          );
        }
        buf.write('}');
        return buf.toString();

      case _ExportFormat.flutter:
        final buf = StringBuffer('abstract final class AppPalette {\n');
        for (int i = 0; i < palette.length; i++) {
          final argb =
              palette[i].color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
          buf.writeln('  static const Color slot${i + 1} = Color(0x$argb);');
        }
        buf.writeln('\n  static const Map<int, Color> brandScale = {');
        for (final stop in scale) {
          final argb =
              stop.color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
          buf.writeln('    ${stop.token}: Color(0x$argb),');
        }
        buf.write('  };\n}');
        return buf.toString();

      case _ExportFormat.designTokens:
        final buf = StringBuffer('{\n  "palette": {\n');
        for (int i = 0; i < palette.length; i++) {
          final comma = i == palette.length - 1 ? '' : ',';
          buf.writeln(
            '    "slot-${i + 1}": { "\$value": "${palette[i].hex}", "\$type": "color" }$comma',
          );
        }
        buf.write('  }\n}');
        return buf.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final code = _generateCode();

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Developer Code & Token Export',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () =>
                      copyWithFeedback(context, code, label: 'Export snippet'),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: StudioPillSelector<_ExportFormat>(
                compact: true,
                options: const [
                  StudioPillOption(value: _ExportFormat.css4, label: 'CSS OKLCH'),
                  StudioPillOption(value: _ExportFormat.tailwind, label: 'Tailwind v4'),
                  StudioPillOption(value: _ExportFormat.flutter, label: 'Flutter'),
                  StudioPillOption(value: _ExportFormat.designTokens, label: 'W3C Tokens'),
                ],
                value: format,
                onChanged: onFormatChanged,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: SelectableText(
                code,
                style: studioMonoStyle(
                  context,
                  fontSize: 11.5,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutLinksCard extends StatelessWidget {
  const _AboutLinksCard();

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HSLuv Color Studio',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Built with the hsluv Dart package & Material 3 HCT / CSS OKLCH color engines.',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.public_rounded, size: 16),
                  label: const Text('hsluv.org'),
                  onPressed: () => _openUrl('https://www.hsluv.org/'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.code_rounded, size: 16),
                  label: const Text('hsluv-dart on GitHub'),
                  onPressed: () =>
                      _openUrl('https://github.com/hsluv/hsluv-dart'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.palette_outlined, size: 16),
                  label: const Text('Material 3 Color System'),
                  onPressed: () =>
                      _openUrl('https://m3.material.io/styles/color/system/overview'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.colorize_rounded, size: 16),
                  label: const Text('OKLCH Color Spec'),
                  onPressed: () => _openUrl('https://oklch.com/'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
