import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hsluvsample/hsinter.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:hsluvsample/util/hsluv_tiny.dart';
import 'package:hsluvsample/util/selected.dart';
import 'package:hsluvsample/util/tiny_color.dart';
import 'package:hsluvsample/util/when.dart';
import 'package:infinite_listview/infinite_listview.dart';

import 'color_with_inter.dart';
import 'colors_list.dart';
import 'util/color_util.dart';
import 'util/constants.dart';

const hsvStr = "HSV";
const hsluvStr = "HSLuv";

const hueStr = "Hue";
const satStr = "Saturation";
const valueStr = "Value";
const lightStr = "Lightness";


class ColorSearchButton extends StatelessWidget {
  const ColorSearchButton({this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color onSurface =
    Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: SizedBox(
        height: 36,
        child: OutlineButton.icon(
          icon: Icon(FeatherIcons.search, size: 16),
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
          borderSide: BorderSide(color: onSurface),
          highlightedBorderColor: onSurface,
          label: Text(color.toHexStr()),
          textColor: onSurface,
          onPressed: () {
//              showSlidersDialog(context, isFirst, widget.color);
          },
          onLongPress: () {
//              copyToClipboard(context, color.toHexStr());
          },
        ),
      ),
    );
  }
}

class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({this.child, this.onPressed});

  final Function onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: RawMaterialButton(
        onPressed: null,
        child: child,
        shape: CircleBorder(
          side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
        elevation: 0.0,
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
    );
  }
}

class HSVerticalPicker extends StatefulWidget {
  const HSVerticalPicker({this.color});

  final Color color;

  @override
  _HSVerticalPickerState createState() => _HSVerticalPickerState();
}

class _HSVerticalPickerState extends State<HSVerticalPicker> {
  bool useHSLuv = true;

  int currentSegment = 0;

  void onValueChanged(int newValue) {
    setState(() {
      currentSegment = newValue;
      useHSLuv = currentSegment == 0;
    });
  }

  final Map<int, Widget> children = const <int, Widget>{
    0: Text('HSLuv'),
    1: Text('HSV'),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${useHSLuv ? "HSLuv" : "HSV"} Picker"),
        elevation: 0,
        backgroundColor: widget.color,
        actions: <Widget>[
//          BorderedIconButton(
//            child: Text(
//              useHSLuv ? "HSV" : "HSL",
//              style: const TextStyle(fontSize: 12),
//            ),
//            onPressed: () {
//              setState(() {
//                useHSLuv = !useHSLuv;
//              });
//            },
//          ),
          ColorSearchButton(color: widget.color),
//          BorderedIconButton(
//            child: Icon(FeatherIcons.copy, size: 16),
//            onPressed: () {
//              setState(() {
//                useHSLuv = !useHSLuv;
//              });
//            },
//          ),
          BorderedIconButton(
            child: Icon(FeatherIcons.moreHorizontal, size: 16),
            onPressed: () {
//              setState(() {
//                useHSLuv = !useHSLuv;
//              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: widget.color,
      body: Column(
        children: <Widget>[
          SizedBox(
            width: 500,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSlidingSegmentedControl<int>(
                thumbColor: widget.color,
                children: children,
                onValueChanged: onValueChanged,
                groupValue: currentSegment,
              ),
            ),
          ),
          Expanded(
            child: WatchBoxBuilder(
              box: Hive.box<dynamic>("settings"),
              builder: (BuildContext context, Box box) => useHSLuv
                  ? HSLuvSelector(
                      color: widget.color,
                      moreColors: box.get("moreItems", defaultValue: false),
                    )
                  : HSVSelector(
                      color: widget.color,
                      moreColors: box.get("moreItems", defaultValue: false),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class HSVSelector extends StatelessWidget {
  const HSVSelector({this.color, this.moreColors = false});

  // initial color
  final Color color;

  final bool moreColors;

  @override
  Widget build(BuildContext context) {
    const String kind = hsvStr;

    // maximum number of items
    final int itemsOnScreen =
        ((MediaQuery.of(context).size.height - 168) / 56).ceil();

    final int toneSize = moreColors ? itemsOnScreen * 2 : itemsOnScreen;
    final int hueSize = moreColors ? 90 : 60;

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
  const HSLuvSelector({this.color, this.moreColors = false});

  // initial color
  final Color color;

  final bool moreColors;

  @override
  Widget build(BuildContext context) {
    const String kind = hsluvStr;

    // maximum number of items
    final int itemsOnScreen =
        ((MediaQuery.of(context).size.height - 168) / 56).ceil();

    final int toneSize = moreColors ? itemsOnScreen * 2 : itemsOnScreen;
    final int hueSize = moreColors ? 90 : 60;

    return HSGenericScreen(
      color: color,
      kind: kind,
      fetchHue: () => hsluvAlternatives(color, hueSize),
      fetchSat: (Color c) =>
          hsluvTones(c, toneSize, 5, 100).convertToInter(kind),
      fetchLight: (Color c) =>
          hsluvLightness(c, toneSize, 5, 90).convertToInter(kind),
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
    expanded = PageStorage.of(context).readState(context,
            identifier: const ValueKey<String>("VerticalSelector")) ??
        0;
  }

  double interval(double value, double min, double max) {
    return math.min(math.max(value, min), max);
  }

  void modifyAndSaveExpanded(int updatedValue) {
    setState(() {
      expanded = updatedValue;
      PageStorage.of(context).writeState(context, expanded,
          identifier: const ValueKey<String>("VerticalSelector"));
    });
  }

  List<ColorWithInter> parseHue() {
    // fetch the hue. If we call this inside the BlocBuilder,
    // we will lose the list position because it will refresh every time.
    final List<Color> hue = widget.fetchHue();

    // apply the diff to the hue.
    return hue.map((Color c) {
      final HSInterColor hsluv = HSInterColor.fromColor(c, widget.kind);
      return ColorWithInter(hsluv.toColor(), hsluv);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final Color rgbColor = widget.color;

    // in the ideal the world they could be calculated in the Bloc &/or in parallel.
    final List<ColorWithInter> hue = parseHue();
    final int hueLen = hue.length;

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
        onTitlePressed: () => modifyAndSaveExpanded(0),
        onColorPressed: (Color c) {
          modifyAndSaveExpanded(0);
          colorSelected(context, c);
        });

    final satWidget = ExpandableColorBar(
        pageKey: widget.kind,
        title: widget.satTitle,
        expanded: expanded,
        sectionIndex: 1,
        listSize: widget.toneSize,
        colorsList: tones,
        onTitlePressed: () => modifyAndSaveExpanded(1),
        onColorPressed: (Color c) {
          modifyAndSaveExpanded(1);
          colorSelected(context, c);
        });

    final valueWidget = ExpandableColorBar(
      pageKey: widget.kind,
      title: widget.lightTitle,
      expanded: expanded,
      sectionIndex: 2,
      listSize: widget.toneSize,
      colorsList: values,
      onTitlePressed: () => modifyAndSaveExpanded(2),
      onColorPressed: (Color c) {
        modifyAndSaveExpanded(2);
        colorSelected(context, c);
      },
    );

    final List<Widget> widgets = <Widget>[hueWidget, satWidget, valueWidget];

    return Theme(
      data: ThemeData.from(
        colorScheme: (rgbColor.computeLuminance() > kLumContrast)
            ? ColorScheme.light(surface: rgbColor)
            : ColorScheme.dark(surface: rgbColor),
        textTheme: const TextTheme(
          caption: TextStyle(fontFamily: "B612Mono"),
          button: TextStyle(fontFamily: "B612Mono"),
        ),
      ).copyWith(
        cardTheme: Theme.of(context).cardTheme.copyWith(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: borderColor),
                borderRadius: BorderRadius.circular(defaultRadius),
              ),
            ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 818),
        child: Column(
          children: <Widget>[
            Expanded(
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
                        builder:
                            (BuildContext ctx, BoxConstraints builder) {
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
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                HSInterColor.fromColor(rgbColor, widget.kind).toString(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: "B612Mono",
                ),
              ),
            ),
            NearestColor(color: rgbColor),
          ],
        ),
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(defaultRadius)),
      child: Text(
        expanded == index ? title : title[0],
        overflow: TextOverflow.ellipsis,
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

  Widget colorCompare(int index) {
    return ColorCompareWidgetDetails(
      kind: pageKey,
      color: colorsList[index],
      compactText: expanded == sectionIndex,
      category: title,
      onPressed: () => onColorPressed(colorsList[index].color),
    );
  }

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
                    return colorCompare(index);
                  },
                )
              : MediaQuery.removePadding(
                  // this is necessary on iOS, else there will be a bottom padding.
                  removeBottom: true,
                  context: context,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: listSize,
                    key: PageStorageKey<String>("$pageKey $sectionIndex"),
                    itemBuilder: (BuildContext context, int index) {
                      return colorCompare(index);
                    },
                  ),
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
      style: Theme.of(context).textTheme.caption.copyWith(color: textColor),
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
    TextStyle theme,
    Color textColor,
    bool isHighlighted,
    double side,
  ) {
    return theme.copyWith(
      fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
      color: textColor.withOpacity(isHighlighted ? 1 : 0.5),
      // 12 doesn't fit all screens.
      fontSize: side < 400 ? 10 : 12,
    );
  }

  Widget richTextColorToHSV(BuildContext context, HSInterColor hsi,
      Color textColor, String category) {
    final TextStyle theme = Theme.of(context).textTheme.caption;

    final shortestSide = MediaQuery.of(context).size.width;

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
            style: themedHSVSpan(
              theme,
              textColor,
              category == "H",
              shortestSide,
            ),
          ),
          TextSpan(
            text: 'S:${hsi.outputSaturation()}% ',
            style:
                themedHSVSpan(theme, textColor, category == "S", shortestSide),
          ),
          TextSpan(
            text: '$letterLorV:${hsi.outputLightness()}%',
            style: themedHSVSpan(
                theme, textColor, category == letterLorV, shortestSide),
          ),
        ],
      ),
    );
  }
}
