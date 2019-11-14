// user defined function
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluvsample/contrast/selectable_sliders.dart';
import 'package:hsluvsample/screen_color_home.dart';
import 'package:hsluvsample/util/color_util.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:hsluvsample/widgets/color_sliders.dart';
import 'package:hsluvsample/widgets/loading_indicator.dart';

import '../blocs/contrast_color/contrast_color_bloc.dart';
import '../blocs/contrast_color/contrast_color_event.dart';
import '../blocs/slider_color/slider_color.dart';

void showSlidersDialog(BuildContext outerContext, Color color, [bool isFirst]) {
  if (isFirst != null) {
    BlocProvider.of<SliderColorBloc>(outerContext).add(MoveColor(color, true));
  }

//  Navigator.push<dynamic>(
//    outerContext,
//    MaterialPageRoute<dynamic>(
//      builder: (context) {
//        return BlocProvider(
//          builder: (context) => SliderColorBloc()..add(MoveColor(color, true)),
//          child: DialogWidget(color, isFirst),
//        );
//      },
//    ),
//  );

  showDialog<dynamic>(
      context: outerContext,
      builder: (BuildContext ctx) {
        return BlocProvider(
          builder: (context) => SliderColorBloc()..add(MoveColor(color, true)),
          child: DialogWidget(color, isFirst),
        );
      });
}

class DialogWidget extends StatelessWidget {
  const DialogWidget(this.color, this.isFirst);

  final bool isFirst;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    bool ignoreFirstOpen = true;

    return BlocBuilder<SliderColorBloc, SliderColorState>(
      builder: (context, state) {
        if (state is SliderColorLoading) {
          return const Scaffold(body: LoadingIndicator());
        }

        // blocs only exist in the outer context, so this is necessary.
//        final context = outerContext;

        final Color color = (state as SliderColorLoaded).rgbColor;

        if (isFirst != null) {
          // only update the ContrastColorBloc when called from inside a
          // contrast screen. Else, ignore this.
          if (ignoreFirstOpen) {
            BlocProvider.of<ContrastColorBloc>(context).add(CMoveColor(
              color,
              isFirst,
            ));
          } else {
            ignoreFirstOpen = !ignoreFirstOpen;
          }
        }

        if ((state as SliderColorLoaded).updateTextField) {
          final clrStr = color.toStr();

          if (controller.text != clrStr) {
            setTextAndPosition(controller, clrStr);
          }
        }

        final rgb = RGBSlider(
            color: color,
            onChanged: (r, g, b) {
              BlocProvider.of<SliderColorBloc>(context).add(MoveRGB(r, g, b));
            });

        final hsluv = HSLuvSlider(
            color: (state as SliderColorLoaded).hsluvColor,
            onChanged: (h, s, l) {
              BlocProvider.of<SliderColorBloc>(context).add(MoveHSLuv(h, s, l));
            });

        final hsv = HSVSlider(
            color: (state as SliderColorLoaded).hsvColor,
            onChanged: (h, s, v) {
              BlocProvider.of<SliderColorBloc>(context).add(MoveHSV(h, s, v));
            });

        final surface = blendColorWithBackground(color);

        final scheme = color.computeLuminance() > kLumContrast
            ? ColorScheme.light(primary: color, surface: surface)
            : ColorScheme.dark(primary: color, surface: surface);

        return Theme(
          data: ThemeData.from(colorScheme: scheme),
          child:
//          Scaffold(
//            appBar: AppBar(
//              title: TextFormColored(controller: controller),
//              backgroundColor: color,
//              elevation: 0,
//            ),
              AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            backgroundColor: color,
//               title: TextFormColored(controller: controller),
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 8),
                TextFormColored(controller: controller),
                Theme(
                  data: ThemeData.from(
                      colorScheme: ColorScheme.dark(surface: surface)),
                  child: Card(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(24.0),
                        bottomLeft: Radius.circular(24.0),
                      ),
                    ),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child:
                          SliderWithSelector([rgb, hsluv, hsv], color, context),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 500,
                    child: FlatButton(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.20),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.0)),
                      child: Text("Select"),
                    ),
                  ),
                ),
//                   const SizedBox(height: 16),
//                  NearestColor(color: color),
              ],
            ),
          ),
//            backgroundColor: color,
//          ),
        );
      },
    );
  }
}

// this is necessary because of https://github.com/flutter/flutter/issues/11416
void setTextAndPosition(TextEditingController controller, String newText,
    {int caretPosition}) {
  final int offset = caretPosition ?? newText.length;
  controller.value = controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty);
}
