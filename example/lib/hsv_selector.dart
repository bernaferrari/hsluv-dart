import 'dart:math' as Math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:material/blocs/blocs.dart';
import 'package:material/colors_repository.dart';
import 'package:material/util/constants.dart';
import 'package:material/util/selected.dart';
import 'package:material/util/tiny_color.dart';
import 'package:material/widgets/loading_indicator.dart';

import 'blocs/slider_color/slider_color.dart';
import 'util/constants.dart';

class BetterColorSelector extends StatefulWidget {
  const BetterColorSelector({this.color});

  final Color color;

  @override
  _BetterColorSelectorState createState() => _BetterColorSelectorState();
}

class _BetterColorSelectorState extends State<BetterColorSelector> {
  double addValue = 0.0;
  double addSaturation = 0.0;
  bool satSelected = false;
  bool fiveSelected = false;
  int expanded = 0;

  @override
  void initState() {
    super.initState();
    expanded = PageStorage.of(context)
        .readState(context, identifier: const ValueKey("HSV Expanded")) ??
        0;
  }

  void modifyAndSaveExpanded(int updatedValue) {
    expanded = updatedValue;
    PageStorage.of(context).writeState(context, expanded,
        identifier: const ValueKey("HSV Expanded"));
  }

  List<ColorWithLum> generateVariants(List<ColorWithLum> lst, bool darker) {
    Iterable<Color> mappedList;

    final change = fiveSelected ? 5 / 100 : 10 / 100;

    if (darker) {
      mappedList = lst.map((f) {
        final hsv = HSVColor.fromColor(f.color);
        if (satSelected) {
          return hsv
              .withSaturation(Math.min(hsv.saturation + change, 1.0))
              .toColor();
        } else {
          return hsv.withValue(Math.min(hsv.value + change, 1.0)).toColor();
        }
      });
    } else {
      mappedList = lst.map((f) {
        final hsv = HSVColor.fromColor(f.color);
        if (satSelected) {
          return hsv
              .withSaturation(Math.max(hsv.saturation - change, 0.0))
              .toColor();
        } else {
          return hsv.withValue(Math.max(hsv.value - change, 0.0)).toColor();
        }
      });
    }

    return mappedList.toList().convertList();
  }

  @override
  Widget build(BuildContext context) {
    final altBase = alternatives(widget.color, 90);

    // Hue
    List<ColorWithLum> hue;
    if (addValue != 0 || addSaturation != 0) {
      hue = altBase
          .map((c) {
            final hsv = HSVColor.fromColor(c);
            final valueDiff =
                Math.min(Math.max(hsv.value - addValue, 0.0), 1.0);

            final satDiff =
                Math.min(Math.max(hsv.saturation - addSaturation, 0.0), 1.0);
            return hsv.withValue(valueDiff).withSaturation(satDiff).toColor();
          })
          .toList()
          .convertList();
    } else {
      hue = altBase.convertList();
    }
    final hueLen = hue.length;

    return BlocBuilder<SliderColorBloc, SliderColorState>(
        builder: (context, state) {
      if (state is SliderColorLoading) {
        return const Scaffold(body: Center(child: LoadingIndicator()));
      }

      final rgbColor = (state as SliderColorLoaded).rgbColor;
      final hsvColor = HSVColor.fromColor(widget.color);

      // maximum number of items
      const toneSize = 20;

      final tones = tonesHSV(rgbColor, toneSize, 0.9 / toneSize, 0.1)
          .reversed
          .toList()
          .convertList();

      final values = valueVariation(rgbColor, toneSize, 0.9 / toneSize, 0.1)
          .reversed
          .toList()
          .convertList();

      final borderColor = (rgbColor.computeLuminance() > kLumContrast)
          ? Colors.black.withOpacity(0.40)
          : Colors.white.withOpacity(0.40);

      final hueWidget = Column(
        children: <Widget>[
          cardTitle("Hue", 0),
          Expanded(child: Card(
            child: InfiniteListView.builder(
              itemBuilder: (context, index) {
                final correctIndex = ((index < 0) ? -index : index) % hueLen;

                return ColorCompareWidgetDetails(
                  hue[correctIndex],
                  compactText: expanded == 0,
                  category: "H",
                  onPressed: () {
                    setState(() {
                      modifyAndSaveExpanded(0);
                    });
                    colorSelected(context, hue[correctIndex].color);
                  },
                );
              },
            ),
          )),
        ],
      );

      final satWidget = Column(
        children: <Widget>[
          cardTitle("Saturation", 1),
          Expanded(
            child: Card(
              child: ListView.builder(
                  itemCount: toneSize,
                  itemBuilder: (context, index) {
                    return ColorCompareWidgetDetails(
                      tones[index],
                      compactText: expanded == 1,
                      category: "S",
                      onPressed: () {
                        setState(() {
                          modifyAndSaveExpanded(1);
                          addSaturation = hsvColor.saturation -
                              HSVColor
                                  .fromColor(tones[index].color)
                                  .saturation;
                        });
                        colorSelected(context, tones[index].color);
                      },
                    );
                  }),
            ),
          ),
        ],
      );

      final valueWidget = Column(children: <Widget>[
        cardTitle("Value", 2),
        Expanded(
          child: Card(
            child: ListView.builder(
                itemCount: toneSize,
                itemBuilder: (context, index) {
                  return ColorCompareWidgetDetails(
                    values[index],
                    compactText: expanded == 2,
                    category: "V",
                    onPressed: () {
                      setState(() {
                        modifyAndSaveExpanded(2);
                        addValue = hsvColor.value -
                            HSVColor
                                .fromColor(values[index].color)
                                .value;
                      });
                      colorSelected(context, values[index].color);
                    },
                  );
                }),
          ),
        ),
      ]);

      final widgets = [hueWidget, satWidget, valueWidget];

      return Theme(
        data: ThemeData.from(
          colorScheme: (rgbColor.computeLuminance() > kLumContrast)
              ? ColorScheme.light(surface: rgbColor)
              : ColorScheme.dark(surface: rgbColor),
        ).copyWith(
          cardTheme: Theme
              .of(context)
              .cardTheme
              .copyWith(
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: borderColor),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: Scaffold(
          backgroundColor: rgbColor,
//          appBar: AppBar(
//            backgroundColor: (state as SliderColorLoaded).rgbColor,
//            elevation: 0,
//          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 818),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(width: 8),
                    for (int i = 0; i < 3; i++) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        flex: (i == expanded) ? 1 : 0,
                        child: LayoutBuilder(
                          // thanks Remi Rousselet for the idea!
                          builder: (ctx, builder) {
                            return AnimatedContainer(
                              width: (i == expanded) ? builder.maxWidth : 64,
                              duration: const Duration(milliseconds: 250),
                              curve: (i == expanded)
                                  ? Curves.easeOut
                                  : Curves.easeIn,
                              child: widgets[i],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget cardTitle(String title, int index) {
    return FlatButton(
      onPressed: () {
        setState(() {
          modifyAndSaveExpanded(index);
        });
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Text(
        expanded == index ? title : title[0],
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: "B612Mono"),
      ),
    );
  }

  Widget cardPicker(String title, Widget picker) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: picker,
          ),
        ],
      ),
    );
  }
}

class ColorCompareWidgetDetails extends StatelessWidget {
  const ColorCompareWidgetDetails(
    this.colorLum, {
    this.onPressed,
        this.compactText = true,
        this.category = "",
  });

  final ColorWithLum colorLum;
  final Function onPressed;
  final bool compactText;
  final String category;

  @override
  Widget build(BuildContext context) {
    final Color textColor = (colorLum.lum < kLumContrast)
        ? Colors.white.withOpacity(0.87)
        : Colors.black87;

    String writtenValue;
    if (category == "S") {
      writtenValue =
      "${(HSVColor
          .fromColor(colorLum.color)
          .saturation * 100).round()}%";
    } else if (category == "V") {
      writtenValue =
      "${(HSVColor
          .fromColor(colorLum.color)
          .value * 100).round()}%";
    } else if (category == "H") {
      writtenValue = "${(HSVColor
          .fromColor(colorLum.color)
          .hue).round()}";
    }

    final Widget cornerText = Text(
      writtenValue,
      style: Theme
          .of(context)
          .textTheme
          .caption
          .copyWith(color: textColor, fontFamily: "B612Mono"),
    );

    final Widget centeredText =
    richTextColorToHSV(context, colorLum.color, textColor, category);

    return Padding(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 56,
        child: MaterialButton(
          elevation: 0,
          color: colorLum.color,
          shape: const RoundedRectangleBorder(),
          onPressed: onPressed ??
              () {
                colorSelected(context, colorLum.color);
              },
          child: compactText ? centeredText : cornerText,
        ),
      ),
    );
  }

  String colorToRGB(Color color) {
    return "R: ${color.red} | G: ${color.green} | B: ${color.blue}";
  }

  TextStyle themedHSVSpan(TextStyle theme, Color textColor,
      bool isHighlighted) {
    return theme.copyWith(
        fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
        color: textColor.withOpacity(isHighlighted ? 1 : 0.5));
  }

  Widget richTextColorToHSV(BuildContext context, Color color, Color textColor,
      String category) {
    final hsv = HSVColor.fromColor(color);
    final TextStyle theme = Theme
        .of(context)
        .textTheme
        .caption
        .copyWith(
      fontFamily: "B612Mono",
    );

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: "H:${hsv.hue.round()} ",
            style: themedHSVSpan(theme, textColor, category == "H"),
          ),
          TextSpan(
            text: 'S:${(hsv.saturation * 100).round()}% ',
            style: themedHSVSpan(theme, textColor, category == "S"),
          ),
          TextSpan(
            text: 'V:${(hsv.value * 100).round()}%',
            style: themedHSVSpan(theme, textColor, category == "V"),
          ),
        ],
      ),
    );
  }

  String colorToHSV(Color color) {
    final hsv = HSVColor.fromColor(color);
    return "H:${hsv.hue.round()} S:${(hsv.saturation * 100).round()}% V:${(hsv
        .value * 100).round()}%";
  }
}
