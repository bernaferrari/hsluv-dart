import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material/widgets/dismiss_keyboard_on_scroll.dart';
import 'package:material/widgets/loading_indicator.dart';

import 'blocs/slider_color/slider_color.dart';

class ColorSliders extends StatelessWidget {
  const ColorSliders(this.rgb, this.hsv, this.hsl);

  final Widget rgb;
  final Widget hsv;
  final Widget hsl;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SliderColorBloc, SliderColorState>(
        builder: (context, state) {
      if (state is SliderColorLoading) {
        return const Scaffold(body: Center(child: LoadingIndicator()));
      }

      return Center(
        child: DismissKeyboardOnScroll(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 818),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                wrapInCard(rgb),
                wrapInCard(hsv),
                wrapInCard(hsl),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget wrapInCard(Widget picker) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24)
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: picker,
      ),
    );
  }
}
