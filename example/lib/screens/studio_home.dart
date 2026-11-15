import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../blocs/studio_cubit.dart';
import '../models/accessibility_utils.dart';
import '../widgets/color_hero_dock.dart';
import '../widgets/studio_theme.dart';
import 'picker_screen.dart';
import 'scales_harmonies_screen.dart';
import 'space_comparison_screen.dart';

/// Responsive 2-panel Chroma Folio shell combining the glowing pigment stage
/// with a single whisper-clean header line and full-height kinetic reels.
class StudioHome extends StatefulWidget {
  const StudioHome({super.key});

  @override
  State<StudioHome> createState() => _StudioHomeState();
}

class _StudioHomeState extends State<StudioHome> {
  int _selectedLens = 0;

  static const _lensOptions = <StudioPillOption<int>>[
    StudioPillOption(value: 0, label: 'Reels', icon: Icons.tune_rounded),
    StudioPillOption(
      value: 1,
      label: 'Spectrum',
      icon: Icons.blur_linear_rounded,
    ),
    StudioPillOption(
      value: 2,
      label: 'Palette',
      icon: Icons.palette_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    ColorNameLookup.ensureLoaded().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool get _isEditingText {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  Widget _buildActiveWorkspace() {
    return switch (_selectedLens) {
      0 => const PickerScreen(key: ValueKey<int>(0)),
      1 => const SpaceComparisonScreen(key: ValueKey<int>(1)),
      _ => const ScalesHarmoniesScreen(key: ValueKey<int>(2)),
    };
  }

  List<Widget> _buildHeaderControlWidgets(
    BuildContext context,
    StudioCubit cubit,
  ) {
    final isStepped = context.select((StudioCubit c) => c.state.isSteppedMode);
    return [
      if (_selectedLens == 0)
        StudioPillSelector<bool>(
          compact: true,
          value: isStepped,
          options: const [
            StudioPillOption<bool>(
              value: true,
              icon: Icons.view_stream_rounded,
              label: 'Wave',
            ),
            StudioPillOption<bool>(
              value: false,
              icon: Icons.gradient_rounded,
              label: 'Silk',
            ),
          ],
          onChanged: cubit.setSteppedMode,
        ),
      StudioPillSelector<int>(
        compact: true,
        options: _lensOptions,
        value: _selectedLens,
        onChanged: (v) => setState(() => _selectedLens = v),
      ),
    ];
  }

  Widget _buildHeaderControls(BuildContext context, StudioCubit cubit) {
    final widgets = _buildHeaderControlWidgets(context, cubit);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widgets.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          widgets[i],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 900;
    final cubit = context.read<StudioCubit>();

    final bodyContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _buildActiveWorkspace(),
    );

    final Widget scaffold;
    if (isWide) {
      scaffold = Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: (size.width * 0.36).clamp(350.0, 440.0),
                  child: const ColorStagePanel(isLandscapeSplit: true),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final brand = Text(
                              'Chroma Folio',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: studioDisplayStyle(
                                context,
                                fontSize: 28,
                                height: 1.0,
                              ),
                            );
                            final controls = _buildHeaderControls(
                              context,
                              cubit,
                            );

                            if (constraints.maxWidth >= 820) {
                              return Row(
                                children: [
                                  brand,
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: controls,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                brand,
                                ..._buildHeaderControlWidgets(context, cubit),
                              ],
                            );
                          },
                        ),
                      ),
                      Expanded(child: bodyContent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      scaffold = Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (size.width >= 540) ...[
                        Text(
                          'Chroma Folio',
                          style: studioDisplayStyle(
                            context,
                            fontSize: 22,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      _buildHeaderControls(context, cubit),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const ColorStagePanel(isLandscapeSplit: false),
                const SizedBox(height: 12),
                Expanded(child: bodyContent),
              ],
            ),
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (!_isEditingText) {
            HapticFeedback.selectionClick();
            cubit.shuffleUnlockedColors();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          if (!_isEditingText) cubit.undo();
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          if (!_isEditingText) cubit.undo();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): () {
          if (!_isEditingText) cubit.redo();
        },
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () {
          if (!_isEditingText) cubit.redo();
        },
      },
      child: Focus(autofocus: true, child: scaffold),
    );
  }
}
