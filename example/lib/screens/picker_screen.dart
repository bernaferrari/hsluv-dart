import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../blocs/studio_cubit.dart';
import '../models/color_spaces.dart';
import '../widgets/slide_picker_column.dart';

/// Right-hand Chroma Folio workspace giving full vertical canvas height to the
/// three kinetic fling channel reels.
class PickerScreen extends StatelessWidget {
  const PickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StudioCubit, StudioState>(
      builder: (context, state) {
        final cubit = context.read<StudioCubit>();
        final channels = state.activeColor.channelsFor(state.activeSpace);
        return _buildRibbonsRow(
          state: state,
          cubit: cubit,
          channels: channels,
        );
      },
    );
  }

  Widget _buildRibbonsRow({
    required StudioState state,
    required StudioCubit cubit,
    required List<ChannelDescriptor> channels,
  }) {
    final children = <Widget>[];
    for (int i = 0; i < channels.length; i++) {
      final descriptor = channels[i];
      if (i > 0) {
        children.add(const SizedBox(width: 14));
      }
      children.add(
        Expanded(
          child: SlidePickerColumn(
            descriptor: descriptor,
            space: state.activeSpace,
            activeColor: state.activeColor,
            isSteppedMode: state.isSteppedMode,
            stepCount: state.stepCount,
            isFocused: false,
            showContrastOverlay: state.showContrastOverlay,
            contrastRefColor: state.contrastRefColor,
            onToggleFocus: () => cubit.toggleFocusedColumn(i),
            onScrubStart: (val) {
              cubit.beginScrub();
              cubit.scrubChannel(i, val);
            },
            onScrubUpdate: (val) => cubit.scrubChannel(i, val),
            onScrubEnd: cubit.endScrub,
            onNudge: (val) {
              cubit.beginScrub();
              cubit.scrubChannel(i, val);
              cubit.endScrub();
            },
          ),
        ),
      );
    }

    return Row(
      key: const ValueKey<String>('kinetic-ribbons'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
