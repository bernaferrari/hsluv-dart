import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluv/flutter/hsluvcolor.dart';
import 'package:infinite_listview/infinite_listview.dart';
import 'package:material/blocs/blocs.dart';
import 'package:material/hsinter.dart';
import 'package:material/util/constants.dart';
import 'package:material/util/hsluv_tiny.dart';
import 'package:material/util/selected.dart';
import 'package:material/util/tiny_color.dart';
import 'package:material/widgets/loading_indicator.dart';

import 'blocs/slider_color/slider_color.dart';
import 'color_with_inter.dart';
import 'util/constants.dart';

const hsvStr = "HSV";
const hsluvStr = "HSLuv";

const hueStr = "Hue";
const satStr = "Saturation";
const valueStr = "Value";
const lightStr = "Lightness";

class HSVSelector extends StatelessWidget {
  const HSVSelector({this.color, this.toneSize = 20, this.hueSize = 90});

  // initial color
  final Color color;

  // maximum number of items
  final int toneSize;

  // maximum number of items
  final int hueSize;

  @override
  Widget build(BuildContext context) {
    const String kind = hsvStr;

    return HSGenericScreen(
      color: color,
      kind: kind,
      fetchHue: () => hueVariations(color, hueSize),
      fetchSat: (Color c) =>
          tonesHSV(c, toneSize, 0.9 / toneSize, 0.1).convertToInter(kind),
      fetchLight: (Color c) => valueVariations(c, toneSize, 0.9 / toneSize, 0.1)
          .convertToInter(kind),
      hueTitle: hueStr,
      satTitle: satStr,
      lightTitle: valueStr,
      toneSize: toneSize,
    );
  }
}

class HSLuvSelector extends StatelessWidget {
  const HSLuvSelector({this.color, this.toneSize = 20, this.hueSize = 90});

  // initial color
  final Color color;

  // maximum number of items
  final int toneSize;

  // maximum number of items
  final int hueSize;

  @override
  Widget build(BuildContext context) {
    const String kind = hsluvStr;

    return HSGenericScreen(
      color: color,
      kind: kind,
      fetchHue: () => hsluvAlternatives(color, hueSize),
      fetchSat: (Color c) =>
          hsluvTones(c, toneSize, 95 / toneSize, 5).convertToInter(kind),
      fetchLight: (Color c) =>
          hsluvLightness(c, toneSize, 95 / toneSize, 0).convertToInter(kind),
      hueTitle: hueStr,
      satTitle: satStr,
      lightTitle: lightStr,
      toneSize: toneSize,
    );
  }
}

class HSGenericScreen extends StatefulWidget {
  const HSGenericScreen({
    this.color,
    this.kind,
    this.fetchHue,
    this.fetchSat,
    this.fetchLight,
    this.hueTitle,
    this.satTitle,
    this.lightTitle,
    this.toneSize,
  });

  final Color color;
  final String kind;
  final List<Color> Function() fetchHue;
  final List<ColorWithInter> Function(Color) fetchSat;
  final List<ColorWithInter> Function(Color) fetchLight;

  final int toneSize;
  final String hueTitle;
  final String satTitle;
  final String lightTitle;

  @override
  _HSGenericScreenState createState() => _HSGenericScreenState();
}

class _HSGenericScreenState extends State<HSGenericScreen> {
  double addValue = 0.0;
  double addSaturation = 0.0;
  bool satSelected = false;
  bool fiveSelected = false;
  int expanded = 0;

  @override
  void initState() {
    super.initState();
    expanded = PageStorage.of(context)
            .readState(context, identifier: ValueKey<String>(widget.kind)) ??
        0;
  }

  double interval(double value, double min, double max) {
    return math.min(math.max(value, min), max);
  }

  void modifyAndSaveExpanded(int updatedValue) {
    expanded = updatedValue;
    PageStorage.of(context).writeState(context, expanded,
        identifier: ValueKey<String>(widget.kind));
  }

  List<ColorWithInter> parseHue() {
    // fetch the hue. If we call this inside the BlocBuilder,
    // we will lose the list position because it will refresh every time.
    final List<Color> hue = widget.fetchHue();

    if (addValue == 0 && addSaturation == 0) {
      return hue.convertToInter(widget.kind);
    }

    // apply the diff to the hue.
    return hue.map((Color c) {
      final HSInterColor hsluv = HSInterColor.fromColor(c, widget.kind);
      final double valueDiff =
          interval(hsluv.lightness - addValue, 0.0, hsluv.maxValue);
      final double satDiff =
          interval(hsluv.saturation - addSaturation, 0.0, hsluv.maxValue);

      final HSInterColor updated =
          hsluv.withSaturation(satDiff).withLightness(valueDiff);

      return ColorWithInter(updated.toColor(), updated);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hue = parseHue();
    final hueLen = hue.length;
    final originalColor = HSInterColor.fromColor(widget.color, widget.kind);

    return BlocBuilder<SliderColorBloc, SliderColorState>(
        builder: (BuildContext context, SliderColorState state) {
      if (state is SliderColorLoading) {
        return const Scaffold(body: Center(child: LoadingIndicator()));
      }

      final Color rgbColor = (state as SliderColorLoaded).rgbColor;

      // in the ideal the world they could be calculated in the Bloc &/or in parallel.
      final List<ColorWithInter> tones = widget.fetchSat(rgbColor);
      final List<ColorWithInter> values = widget.fetchLight(rgbColor);

      final Color borderColor = (rgbColor.computeLuminance() > kLumContrast)
          ? Colors.black.withOpacity(0.40)
          : Colors.white.withOpacity(0.40);

      final Widget hueWidget = ExpandableColorBar(
          pageKey: widget.kind,
          title: widget.hueTitle,
          expanded: expanded,
          sectionIndex: 0,
          listSize: hueLen,
          isInfinite: true,
          colorsList: hue,
          onTitlePressed: () {
            setState(() {
              modifyAndSaveExpanded(0);
            });
          },
          onColorPressed: (Color c) {
            setState(() {
              modifyAndSaveExpanded(0);
            });
            colorSelected(context, c);
          });

      final satWidget = ExpandableColorBar(
          pageKey: widget.kind,
          title: widget.satTitle,
          expanded: expanded,
          sectionIndex: 1,
          listSize: widget.toneSize,
          colorsList: tones,
          onTitlePressed: () {
            setState(() {
              modifyAndSaveExpanded(1);
            });
          },
          onColorPressed: (Color c) {
            setState(() {
              modifyAndSaveExpanded(1);
              addSaturation = originalColor.saturation -
                  HSInterColor.fromColor(c, widget.kind).saturation;
            });
            colorSelected(context, c);
          });

      final valueWidget = ExpandableColorBar(
        pageKey: widget.kind,
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
                HSInterColor.fromColor(c, widget.kind).lightness;
          });
          colorSelected(context, c);
        },
      );

      final List<Widget> widgets = <Widget>[hueWidget, satWidget, valueWidget];

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
                    for (int i = 0; i < 3; i++) ...<Widget>[
                      const SizedBox(width: 8),
                      Flexible(
                        flex: (i == expanded) ? 1 : 0,
                        child: LayoutBuilder(
                          // thanks Remi Rousselet for the idea!
                          builder: (BuildContext ctx, BoxConstraints builder) {
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

class _ExpandableTitle extends StatelessWidget {
  const _ExpandableTitle({
    this.title,
    this.expanded,
    this.index,
    this.onTitlePressed,
  });

  final Function onTitlePressed;
  final String title;
  final int expanded;
  final int index;

  @override
  Widget build(BuildContext context) {
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
}

class ExpandableColorBar extends StatelessWidget {
  const ExpandableColorBar({
    this.pageKey,
    this.title,
    this.expanded,
    this.sectionIndex,
    this.listSize,
    this.colorsList,
    this.onTitlePressed,
    this.onColorPressed,
    this.isInfinite = false,
  });

  final Function onTitlePressed;
  final Function(Color) onColorPressed;
  final List<ColorWithInter> colorsList;
  final String title;
  final String pageKey;
  final int expanded;
  final int sectionIndex;
  final int listSize;
  final bool isInfinite;

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      _ExpandableTitle(
        title: title,
        index: sectionIndex,
        expanded: expanded,
        onTitlePressed: onTitlePressed,
      ),
      Expanded(
        child: Card(
          child: isInfinite
              ? InfiniteListView.builder(
                  key: PageStorageKey<String>("$pageKey $sectionIndex"),
                  itemBuilder: (BuildContext context, int absoluteIndex) {
                    final int index = absoluteIndex.abs() % listSize;

                    return ColorCompareWidgetDetails(
                      kind: pageKey,
                      color: colorsList[index],
                      compactText: expanded == sectionIndex,
                      category: title,
                      onPressed: () => onColorPressed(colorsList[index].color),
                    );
                  },
                )
              : ListView.builder(
                  itemCount: listSize,
                  key: PageStorageKey<String>("$pageKey $sectionIndex"),
                  itemBuilder: (BuildContext context, int index) {
                    return ColorCompareWidgetDetails(
                      kind: pageKey,
                      color: colorsList[index],
                      compactText: expanded == sectionIndex,
                      category: title,
                      onPressed: () => onColorPressed(colorsList[index].color),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

class ColorCompareWidgetDetails extends StatelessWidget {
  const ColorCompareWidgetDetails({
    this.color,
    this.onPressed,
    this.compactText = true,
    this.category = "",
    this.kind,
  });

  final ColorWithInter color;
  final Function onPressed;
  final bool compactText;
  final String category;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final Color textColor = (color.lum < kLumContrast)
        ? Colors.white.withOpacity(0.87)
        : Colors.black87;

    final HSInterColor inter = color.inter;

    final String writtenValue = when<String>({
      () => category == hueStr: () => inter.hue.round().toString(),
      () => category == satStr: () => "${inter.outputSaturation()}%",
      () => category == lightStr || category == valueStr: () =>
          "${inter.outputLightness()}%",
    });

    final Widget cornerText = Text(
      writtenValue,
      style: Theme.of(context)
          .textTheme
          .caption
          .copyWith(color: textColor, fontFamily: "B612Mono"),
    );

    final Widget centeredText =
        richTextColorToHSV(context, inter, textColor, category[0]);

    return Padding(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 56,
        child: MaterialButton(
          elevation: 0,
          color: color.color,
          shape: const RoundedRectangleBorder(),
          onPressed: onPressed ??
              () {
                colorSelected(context, color.color);
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
      color: textColor.withOpacity(isHighlighted ? 1 : 0.5),
    );
  }

  Widget richTextColorToHSV(BuildContext context, HSInterColor hsi,
      Color textColor, String category) {
    final TextStyle theme = Theme.of(context).textTheme.caption.copyWith(
          fontFamily: "B612Mono",
        );

    final String letterLorV = when({
      () => kind == hsluvStr: () => "L",
      () => kind == hsvStr: () => "V",
    });

    return RichText(
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: "H:${hsi.hue.round()} ",
            style: themedHSVSpan(theme, textColor, category == "H"),
          ),
          TextSpan(
            text: 'S:${hsi.outputSaturation()}% ',
            style: themedHSVSpan(theme, textColor, category == "S"),
          ),
          TextSpan(
            text: '$letterLorV:${hsi.outputLightness()}%',
            style: themedHSVSpan(theme, textColor, category == letterLorV),
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

T when<T>(Map<bool Function(), T Function()> conditions, {T orElse()}) {
  for (final dynamic entry in conditions.entries) {
    if (entry.key()) {
      return entry.value();
    }
  }
  return orElse();
}
