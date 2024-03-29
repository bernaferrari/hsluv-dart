import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hsluv/hsluvcolor.dart';

import '../color_with_inter.dart';
import '../hsinter.dart';
import '../util/color_util.dart';
import '../util/constants.dart';
import '../util/selected.dart';
import '../util/widget_space.dart';
import 'app_bar_actions.dart';
import 'hsluv_selector.dart';
import 'hsv_selector.dart';
import 'picker_list.dart';

const hsvStr = "HSV";
const hsluvStr = "HSLuv";

const hueStr = "Hue";
const satStr = "Saturation";
const valueStr = "Value";
const lightStr = "Lightness";

class HSVerticalPicker extends StatefulWidget {
  const HSVerticalPicker({
    required this.color,
    required this.hsLuvColor,
    Key? key,
  }) : super(key: key);

  final Color color;
  final HSLuvColor hsLuvColor;

  @override
  State<HSVerticalPicker> createState() => _HSVerticalPickerState();
}

class _HSVerticalPickerState extends State<HSVerticalPicker> {
  late int currentSegment = PageStorage.of(context).readState(context,
          identifier: const ValueKey("verticalSelected")) ??
      0;

  void onValueChanged(int? newValue) {
    if (newValue == null) {
      return;
    }

    setState(() {
      currentSegment = newValue;
      PageStorage.of(context).writeState(context, currentSegment,
          identifier: const ValueKey("verticalSelected"));
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
        title: Text(
          "${currentSegment == 0 ? "HSLuv" : "HSV"} Picker",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        elevation: 0,
        centerTitle: false,
        backgroundColor: widget.color,
        actions: <Widget>[
          Center(child: ColorSearchButton(color: widget.color)),
          const SizedBox(width: 8),
          // OutlinedIconButton(
          //   child: const Icon(FeatherIcons.moreHorizontal, size: 16),
          //   onPressed: () {
          //     showDialog<dynamic>(
          //         context: context,
          //         builder: (_) {
          //           return AlertDialog(
          //             contentPadding: const EdgeInsets.all(24),
          //             shape: RoundedRectangleBorder(
          //               borderRadius: BorderRadius.circular(16),
          //             ),
          //             backgroundColor: widget.color,
          //             content: Card(
          //               clipBehavior: Clip.antiAlias,
          //               margin: EdgeInsets.zero,
          //               color: Theme.of(context)
          //                   .colorScheme
          //                   .background
          //                   .withOpacity(kVeryTransparent),
          //               elevation: 0,
          //               child: const MoreColors(activeColor: Colors.green),
          //             ),
          //           );
          //         });
          //   },
          // ),
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
                left: 16.0,
                right: 16,
                top: 16,
                bottom: 12,
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.20),
                thumbColor: compositeColors(
                  // this is needed, else component gets ugly with shadow.
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
            child:
                // child: WatchBoxBuilder(
                //   box: Hive.box<dynamic>("settings"),
                // builder: (_ context, Box box) => currentSegment == 0
                currentSegment == 0
                    ? HSLuvSelector(
                        color: widget.hsLuvColor,
                        // moreColors: box.get("moreItems", defaultValue: false),
                      )
                    : HSVSelector(
                        color: widget.color,
                        // moreColors: box.get("moreItems", defaultValue: false),
                      ),
          ),
        ],
      ),
    );
  }
}

class HSGenericScreen extends StatefulWidget {
  const HSGenericScreen({
    required this.color,
    required this.kind,
    required this.fetchHue,
    required this.fetchSat,
    required this.fetchLight,
    required this.hueTitle,
    required this.satTitle,
    required this.lightTitle,
    required this.toneSize,
    Key? key,
  }) : super(key: key);

  final HSInterColor color;
  final HSInterType kind;
  final List<ColorWithInter> Function() fetchHue;
  final List<ColorWithInter> Function() fetchSat;
  final List<ColorWithInter> Function() fetchLight;

  final int toneSize;
  final String hueTitle;
  final String satTitle;
  final String lightTitle;

  @override
  State<HSGenericScreen> createState() => _HSGenericScreenState();
}

class _HSGenericScreenState extends State<HSGenericScreen> {
  double addValue = 0.0;
  double addSaturation = 0.0;
  bool satSelected = false;
  bool fiveSelected = false;
  late int expanded = PageStorage.of(context).readState(context,
          identifier: const ValueKey("VerticalSelector")) ??
      0;

  double interval(double value, double min, double max) {
    return math.min(math.max(value, min), max);
  }

  void modifyAndSaveExpanded(int updatedValue) {
    setState(() {
      expanded = updatedValue;
      PageStorage.of(context).writeState(context, expanded,
          identifier: const ValueKey("VerticalSelector"));
    });
  }

  @override
  Widget build(BuildContext context) {
    final HSInterColor color = widget.color;
    // final Color rgbColor = widget.color.toColor();

    // in the ideal the world they could be calculated in the Bloc &/or in parallel.
    final List<ColorWithInter> hue = widget.fetchHue();
    final int hueLen = hue.length;

    final List<ColorWithInter> tones = widget.fetchSat();
    final List<ColorWithInter> values = widget.fetchLight();

    // final isColorBrighterThanContrast =
    //     color.outputLightness() >= kLightnessThreshold;

    // final Color borderColor = isColorBrighterThanContrast
    //     ? Colors.black.withOpacity(0.40)
    //     : Colors.white.withOpacity(0.40);

    final Widget hueWidget = ExpandableColorBar(
        kind: widget.kind,
        title: widget.hueTitle,
        expanded: expanded,
        sectionIndex: 0,
        listSize: hueLen,
        isInfinite: true,
        colorsList: hue,
        onTitlePressed: () => modifyAndSaveExpanded(0),
        onColorPressed: (c) {
          modifyAndSaveExpanded(0);
          colorSelected(context, c);
        });

    final satWidget = ExpandableColorBar(
        kind: widget.kind,
        title: widget.satTitle,
        expanded: expanded,
        sectionIndex: 1,
        listSize: widget.toneSize,
        colorsList: tones,
        onTitlePressed: () => modifyAndSaveExpanded(1),
        onColorPressed: (c) {
          modifyAndSaveExpanded(1);
          colorSelected(context, c);
        });

    final valueWidget = ExpandableColorBar(
      kind: widget.kind,
      title: widget.lightTitle,
      expanded: expanded,
      sectionIndex: 2,
      listSize: widget.toneSize,
      colorsList: values,
      onTitlePressed: () => modifyAndSaveExpanded(2),
      onColorPressed: (c) {
        modifyAndSaveExpanded(2);
        colorSelected(context, c);
      },
    );

    final List<Widget> widgets = <Widget>[hueWidget, satWidget, valueWidget];

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.copyWith(
              bodySmall: GoogleFonts.b612Mono(),
              labelLarge: GoogleFonts.b612Mono(),
            ),
        cardTheme: Theme.of(context).cardTheme.copyWith(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.40),
                ),
                borderRadius: BorderRadius.circular(defaultRadius),
              ),
            ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 818),
          child: Column(
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: spaceRow(
                      16,
                      <Widget>[
                        for (int i = 0; i < 3; i++)
                          Flexible(
                            flex: (i == expanded) ? 1 : 0,
                            child: LayoutBuilder(
                              // thanks Remi Rousselet for the idea!
                              builder: (_, builder) {
                                return AnimatedContainer(
                                  width:
                                      (i == expanded) ? builder.maxWidth : 64,
                                  duration: const Duration(milliseconds: 250),
                                  curve: (i == expanded)
                                      ? Curves.easeOut
                                      : Curves.easeIn,
                                  child: widgets[i],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12),
                child: Text(
                  color.toString(),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.b612Mono(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
