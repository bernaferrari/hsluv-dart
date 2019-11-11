// user defined function
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluvsample/contrast/selectable_sliders.dart';
import 'package:hsluvsample/screen_color_home.dart';
import 'package:hsluvsample/util/color_util.dart';
import 'package:hsluvsample/widgets/color_sliders.dart';
import 'package:hsluvsample/widgets/loading_indicator.dart';

import '../blocs/contrast_color/contrast_color_bloc.dart';
import '../blocs/contrast_color/contrast_color_event.dart';
import '../blocs/slider_color/slider_color.dart';

void showSlidersDialog(BuildContext outerContext, bool isFirst, Color color) {
  BlocProvider.of<SliderColorBloc>(outerContext).add(MoveColor(color, true));
  bool ignoreFirstOpen = true;

  showDialog<dynamic>(
      context: outerContext,
      builder: (BuildContext ctx) {
        final TextEditingController controller = TextEditingController();

        return BlocBuilder<SliderColorBloc, SliderColorState>(
          builder: (context, state) {
            if (state is SliderColorLoading) {
              return const Scaffold(body: LoadingIndicator());
            }

            // blocs only exist in the outer context, so this is necessary.
            final context = outerContext;

            final Color color = (state as SliderColorLoaded).rgbColor;

            if (ignoreFirstOpen) {
              BlocProvider.of<ContrastColorBloc>(context).add(CMoveColor(
                color,
                isFirst,
              ));
            } else {
              ignoreFirstOpen = !ignoreFirstOpen;
            }

            if ((state as SliderColorLoaded).updateTextField) {
              final clrStr = color.toStr();

              if (controller.text != clrStr) {
                controller.text = clrStr;
              }
            }

            final rgb = RGBSlider(
                color: color,
                onChanged: (r, g, b) {
                  BlocProvider.of<SliderColorBloc>(context)
                      .add(MoveRGB(r, g, b));
                });

            final hsluv = HSLuvSlider(
                color: (state as SliderColorLoaded).hsluvColor,
                onChanged: (h, s, l) {
                  BlocProvider.of<SliderColorBloc>(context)
                      .add(MoveHSLuv(h, s, l));
                });

            final hsv = HSVSlider(
                color: (state as SliderColorLoaded).hsvColor,
                onChanged: (h, s, v) {
                  BlocProvider.of<SliderColorBloc>(context)
                      .add(MoveHSV(h, s, v));
                });

            // return object of type Dialog
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              title: TextFormColored(controller: controller),
              backgroundColor: color,
              content: SliderWithSelector(rgb, hsluv, hsv, context),
            );
          },
        );
      });
}
