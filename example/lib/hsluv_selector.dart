import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluv/flutter/hsluvcolor.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:material/blocs/blocs.dart';
import 'package:material/colors_repository.dart';
import 'package:material/util/constants.dart';
import 'package:material/util/hsluv_tiny.dart';
import 'package:material/util/selected.dart';
import 'package:material/widgets/loading_indicator.dart';

import 'blocs/slider_color/slider_color.dart';
import 'util/constants.dart';

class HSLuvSelector extends StatelessWidget {
  const HSLuvSelector({this.color, this.toneSize = 20});

  // initial color
  final Color color;

  // maximum number of items
  final int toneSize;

  @override
  Widget build(BuildContext context) {
    return HSLuvSelectorGeneric(
      color: color,
      valueKey: "HSLuv",
      fetchHue: () => hsluvAlternatives(color, 90),
      fetchSat: (Color c) =>
          hsluvTones(c, toneSize, 95 / toneSize, 5).convertList(),
      fetchLight: (Color c) =>
          hsluvLightness(c, toneSize, 95 / toneSize, 0).convertList(),
      hueTitle: "Hue",
      satTitle: "Saturation",
      lightTitle: "Lightness",
      toneSize: toneSize,
    );
  }
}

class HSLuvSelectorGeneric extends StatefulWidget {
  const HSLuvSelectorGeneric({
    this.color,
    this.valueKey,
    this.fetchHue,
    this.fetchSat,
    this.fetchLight,
    this.hueTitle,
    this.satTitle,
    this.lightTitle,
    this.toneSize,
  });

  final Color color;
  final String valueKey;
  final List<Color> Function() fetchHue;
  final List<ColorWithLum> Function(Color) fetchSat;
  final List<ColorWithLum> Function(Color) fetchLight;

  final int toneSize;
  final String hueTitle;
  final String satTitle;
  final String lightTitle;

  @override
  _HSLuvSelectorGenericState createState() => _HSLuvSelectorGenericState();
}

class _HSLuvSelectorGenericState extends State<HSLuvSelectorGeneric> {
  double addValue = 0.0;
  double addSaturation = 0.0;
  bool satSelected = false;
  bool fiveSelected = false;
  int expanded = 0;

  @override
  void initState() {
    super.initState();
    expanded = PageStorage.of(context)
            .readState(context, identifier: ValueKey(widget.valueKey)) ??
        0;
  }

  double interval(double value, double min, double max) {
    return math.min(math.max(value, min), max);
  }

  void modifyAndSaveExpanded(int updatedValue) {
    expanded = updatedValue;
    PageStorage.of(context)
        .writeState(context, expanded, identifier: ValueKey(widget.valueKey));
  }

  List<ColorWithLum> fetchHueForHSLuv() {
    // fetch the hue. If we call this inside the BlocBuilder,
    // we will lose the list position because it will refresh every time.
    final List<Color> hue = widget.fetchHue();

    if (addValue == 0 && addSaturation == 0) {
      return hue.convertList();
    }

    // apply the diff to the hue.
    return hue
        .map((Color c) {
          final hsluv = HSLuvColor.fromColor(c);
          final valueDiff = interval(hsluv.lightness - addValue, 0.0, 100.0);
          final satDiff =
              interval(hsluv.saturation - addSaturation, 0.0, 100.0);

          return hsluv
              .withSaturation(satDiff)
              .withLightness(valueDiff)
              .toColor();
        })
        .toList()
        .convertList();
  }

  @override
  Widget build(BuildContext context) {
    // todo HSV
    final hue = fetchHueForHSLuv();

    final hueLen = hue.length;

    // todo HSV
    final originalColor = HSLuvColor.fromColor(widget.color);

    return BlocBuilder<SliderColorBloc, SliderColorState>(
        builder: (context, state) {
      if (state is SliderColorLoading) {
        return const Scaffold(body: Center(child: LoadingIndicator()));
      }

      final rgbColor = (state as SliderColorLoaded).rgbColor;

      final tones = widget.fetchSat(rgbColor);
      final values = widget.fetchLight(rgbColor);

      final borderColor = (rgbColor.computeLuminance() > kLumContrast)
          ? Colors.black.withOpacity(0.40)
          : Colors.white.withOpacity(0.40);

      final hueWidget = Column(
        children: <Widget>[
          cardTitle(widget.hueTitle, 0),
          Expanded(child: Card(
            child: InfiniteListView.builder(
              itemBuilder: (context, index) {
                // mirror the index value, so that ListView works in both ways.
                final correctIndex = index.abs() % hueLen;

                return ColorCompareWidgetDetails(
                  hue[correctIndex],
                  compactText: expanded == 0,
                  category: widget.hueTitle,
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
          cardTitle(widget.satTitle, 1),
          Expanded(
            child: Card(
              child: ListView.builder(
                itemCount: widget.toneSize,
                itemBuilder: (context, index) {
                  return ColorCompareWidgetDetails(
                    tones[index],
                    compactText: expanded == 1,
                    category: widget.satTitle,
                    onPressed: () {
                      setState(() {
                        modifyAndSaveExpanded(1);
                        addSaturation = originalColor.saturation -
                            HSLuvColor.fromColor(tones[index].color).saturation;
                      });
                      colorSelected(context, tones[index].color);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      );

      final valueWidget = ExpandableColorBar(
        title: widget.lightTitle,
        expanded: expanded,
        sectionIndex: 2,
        listSize: widget.toneSize,
        colorsList: values,
        onTitlePressed: () {
          setState(() {
            modifyAndSaveExpanded(2);
          });
        },
        onColorPressed: (Color c) {
          setState(() {
            modifyAndSaveExpanded(2);
            addValue = originalColor.lightness -
                HSLuvColor.fromColor(c).lightness;
          });
          colorSelected(context, c);
        },
      );

      final widgets = [hueWidget, satWidget, valueWidget];

      return Theme(
        data: ThemeData.from(
          colorScheme: (rgbColor.computeLuminance() > kLumContrast)
              ? ColorScheme.light(surface: rgbColor)
              : ColorScheme.dark(surface: rgbColor),
        ).copyWith(
          cardTheme: Theme.of(context).cardTheme.copyWith(
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
}

class ExpandableColorBar extends StatelessWidget {
  const ExpandableColorBar({
    this.title,
    this.expanded,
    this.sectionIndex,
    this.listSize = 0,
    this.colorsList,
    this.onTitlePressed,
    this.onColorPressed,
  });

  final Function onTitlePressed;
  final Function(Color) onColorPressed;
  final List<ColorWithLum> colorsList;
  final String title;
  final int expanded;
  final int sectionIndex;
  final int listSize;

  Widget cardTitle(String title, int index) {
    return FlatButton(
      onPressed: onTitlePressed,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Text(
        expanded == index ? title : title[0],
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: "B612Mono"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Function(BuildContext, int) itemBuilder = (context, index) {
      return ColorCompareWidgetDetails(
        colorsList[index],
        compactText: expanded == sectionIndex,
        category: title,
        onPressed: () => onColorPressed(colorsList[index].color),
      );
    };

    return Column(children: <Widget>[
      cardTitle(title, sectionIndex),
      Expanded(
        child: Card(
          child: listSize == 0
              ? InfiniteListView.builder(itemBuilder: itemBuilder)
              : ListView.builder(
                  itemCount: listSize,
                  itemBuilder: itemBuilder,
                ),
        ),
      ),
    ]);
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
    if (category == "Saturation") {
      writtenValue =
          "${(HSLuvColor.fromColor(colorLum.color).saturation).round()}%";
    } else if (category == "Lightness") {
      writtenValue =
          "${(HSLuvColor.fromColor(colorLum.color).lightness).round()}%";
    } else if (category == "Hue") {
      writtenValue = "${(HSLuvColor.fromColor(colorLum.color).hue).round()}";
    }

    final Widget cornerText = Text(
      writtenValue,
      style: Theme.of(context)
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

  TextStyle themedHSVSpan(
      TextStyle theme, Color textColor, bool isHighlighted) {
    return theme.copyWith(
        fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
        color: textColor.withOpacity(isHighlighted ? 1 : 0.5));
  }

  Widget richTextColorToHSV(
      BuildContext context, Color color, Color textColor, String category) {
    final hsv = HSLuvColor.fromColor(color);
    final TextStyle theme = Theme.of(context).textTheme.caption.copyWith(
          fontFamily: "B612Mono",
        );

    // todo HSV
    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: "H:${hsv.hue.round()} ",
            style: themedHSVSpan(theme, textColor, category == "H"),
          ),
          TextSpan(
            text: 'S:${(hsv.saturation).round()}% ',
            style: themedHSVSpan(theme, textColor, category == "S"),
          ),
          TextSpan(
            text: 'L:${(hsv.lightness).round()}%',
            style: themedHSVSpan(theme, textColor, category == "L"),
          ),
        ],
      ),
    );
  }

  String colorToHSLuv(Color color) {
    final hsluv = HSLuvColor.fromColor(color);
    return "H:${hsluv.hue.round()} S:${hsluv.saturation.round()}% L:${hsluv.lightness.round()}%";
  }

  String colorToHSV(Color color) {
    final hsv = HSVColor.fromColor(color);
    return "H:${hsv.hue.round()} S:${(hsv.saturation * 100).round()}% V:${(hsv.value * 100).round()}%";
  }

  String colorToRGB(Color color) {
    return "R:${color.red} G:${color.green} B:${color.blue}";
  }
}
