import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hsluvsample/hsinter.dart';
import 'package:hsluvsample/util/color_util.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:hsluvsample/util/selected.dart';
import 'package:hsluvsample/vertical_picker/picker_list.dart';

import '../color_with_inter.dart';
import '../screen_about.dart';
import '../util/constants.dart';
import 'app_bar.dart';
import 'hsluv_selector.dart';
import 'hsv_selector.dart';

const hsvStr = "HSV";
const hsluvStr = "HSLuv";

const hueStr = "Hue";
const satStr = "Saturation";
const valueStr = "Value";
const lightStr = "Lightness";

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
    0: Text("HSLuv"),
    1: Text("HSV"),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${useHSLuv ? "HSLuv" : "HSV"} Picker"),
        elevation: 0,
        backgroundColor: widget.color,
        actions: <Widget>[
          ColorSearchButton(color: widget.color),
          BorderedIconButton(
            child: Icon(FeatherIcons.moreHorizontal, size: 16),
            onPressed: () {
              showDialog<dynamic>(
                  context: context,
                  builder: (BuildContext ctx) {
                    return AlertDialog(
                      contentPadding: const EdgeInsets.all(24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      backgroundColor: widget.color,
                      content: Card(
                        clipBehavior: Clip.antiAlias,
                        margin: EdgeInsets.zero,
                        color: compositeColors(
                          Theme.of(context).colorScheme.background,
                          Theme.of(context).colorScheme.primary,
                          0.20,
                        ),
                        elevation: 0,
                        child: MoreColors(
                          activeColor: Colors.green,
                        ),
                      ),
                    );
                  });
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
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16, top: 16, bottom: 12),
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.20),
                thumbColor: compositeColors(
                  Theme.of(context).colorScheme.background,
                  Theme.of(context).colorScheme.primary,
                  0.20,
                ),
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
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Text(
                HSInterColor.fromColor(rgbColor, widget.kind).toString(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: "B612Mono",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
