import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hsluvsample/blocs/contrast_color/contrast_color_event.dart';
import 'package:hsluvsample/blocs/contrast_color/contrast_color_state.dart';
import 'package:hsluvsample/contrast/color_with_contrast.dart';
import 'package:hsluvsample/contrast/shuffle_color.dart';
import 'package:hsluvsample/hsinter.dart';
import 'package:hsluvsample/util/color_util.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:hsluvsample/util/hsluv_tiny.dart';
import 'package:hsluvsample/util/selected.dart';
import 'package:hsluvsample/util/tiny_color.dart';
import 'package:hsluvsample/util/when.dart';
import 'package:hsluvsample/widgets/loading_indicator.dart';

import '../blocs/contrast_color/contrast_color.dart';
import '../util/constants.dart';
import 'contrast_dialog.dart';
import 'contrast_list.dart';
import 'contrast_util.dart';

class ContrastScreen extends StatefulWidget {
  const ContrastScreen({this.color});

  final Color color;

  @override
  _ContrastScreenState createState() => _ContrastScreenState();
}

class _ContrastScreenState extends State<ContrastScreen> {
  bool useHSLuv = true;

  final int r = Random().nextInt(102);

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
    return BlocProvider<ContrastColorBloc>(
      builder: (ctx) => ContrastColorBloc()
        ..add(LoadInit(widget.color, Color(int.parse("0xFF${colorClaim[r]}")))),
      child: Theme(
        data: ThemeData.from(colorScheme: const ColorScheme.dark()),
        child: Scaffold(
          appBar: buildAppBar(),
          body: Column(
            children: <Widget>[
              SizedBox(
                width: 500,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0, right: 16, top: 16, bottom: 12),
                  child: CupertinoSlidingSegmentedControl<int>(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.20),
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
              Expanded(child: buildFlex()),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFlex() {
    return WatchBoxBuilder(
      box: Hive.box<dynamic>("settings"),
      builder: (BuildContext context, Box box) {
        final bool more = box.get("moreItems", defaultValue: false);

        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          // on iPad, always vertical.
          direction: MediaQuery.of(context).size.shortestSide > 600
              ? Axis.vertical
              : MediaQuery.of(context).orientation == Orientation.landscape
                  ? Axis.horizontal
                  : Axis.vertical,
          children: <Widget>[
            Expanded(
              child: useHSLuv
                  ? HSLuvSelector2(isFirst: true, moreColors: more)
                  : HSVSelector2(isFirst: true, moreColors: more),
            ),
            Expanded(
              child: useHSLuv
                  ? HSLuvSelector2(isFirst: false, moreColors: more)
                  : HSVSelector2(isFirst: false, moreColors: more),
            ),
          ],
        );
      },
    );
  }

  Widget buildAppBar() {
    return AppBar(
      title: const Text("Contrast Compare"),
      backgroundColor: blendColorWithBackground(widget.color),
      elevation: 0,
      actions: [
//            IconButton(
//              icon: Icon(Icons.help_outline),
//              onPressed: () {
//                showDialog<dynamic>(context: context, builder: (BuildContext context) {
//                  return AlertDialog(
//                    title: Text("WCAG 2.1"),
//                    content: Text(
//                      "\n3.0:1 minimum for texts larger than 18pt (AA+).\n4.5:1 minimum for texts smaller than 18pt (AA).\n7.0:1 minimum is preferred, when possible (AAA).",
//                    ),
//                  );
//                });
//              },
//            ),
//        IconButton(
//          icon: RawMaterialButton(
//            onPressed: null,
//            child: Text(
//              useHSLuv ? "HSV" : "HSL",
//              style: const TextStyle(fontSize: 12),
//            ),
//            shape: CircleBorder(
//              side: BorderSide(color: Theme.of(context).colorScheme.onSurface),
//            ),
//            elevation: 0.0,
//            padding: EdgeInsets.zero,
//          ),
//          onPressed: () {
//            setState(() {
//              useHSLuv = !useHSLuv;
//            });
//          },
//        ),

//        ToggleButtons(
//          children: const [
//            Padding(
//              padding: EdgeInsets.symmetric(horizontal: 12.0),
//              child: Text(
//                "HSV",
//                style: TextStyle(fontFamily: "B612Mono"),
//              ),
//            ),
//            Padding(
//              padding: EdgeInsets.symmetric(horizontal: 12.0),
//              child: Text(
//                "HSLuv",
//                style: TextStyle(fontFamily: "B612Mono"),
//              ),
//            ),
//          ],
//          isSelected: [
//            useHSLuv == false,
//            useHSLuv == true,
//          ],
//          onPressed: (selectedIndex) {
//            setState(() {
//              useHSLuv = selectedIndex != 0;
//            });
//          },
//        ),
      ],
    );
  }
}

class HSVSelector2 extends StatelessWidget {
  const HSVSelector2({
    this.isFirst,
    this.moreColors,
  });

  // maximum number of items
  final bool moreColors;

  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    const String kind = hsvStr;

    // maximum number of items
    final int itemsOnScreen =
        ((MediaQuery.of(context).size.height - 112) / 56).ceil();

    final int toneSize = moreColors ? itemsOnScreen * 2 : itemsOnScreen;
    final int hueSize = moreColors ? 90 : 45;

    return ContrastHorizontalPicker(
      kind: kind,
      fetchHue: (Color c) => hueVariations(c, hueSize),
      fetchSat: (Color c, Color otherColor) =>
          tonesHSV(c, toneSize, 1 / toneSize, 0)
              .convertToInterContrast(kind, otherColor),
      fetchLight: (Color c, Color otherColor) =>
          valueVariations(c, toneSize, 1 / toneSize, 0)
              .convertToInterContrast(kind, otherColor),
      hueTitle: hueStr,
      satTitle: satStr,
      lightTitle: valueStr,
      toneSize: toneSize,
      isFirst: isFirst,
    );
  }
}

class HSLuvSelector2 extends StatelessWidget {
  const HSLuvSelector2({
    this.moreColors = false,
    this.isFirst,
  });

  // maximum number of items
  final bool moreColors;

  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    const String kind = hsluvStr;

    // maximum number of items
    final double width = MediaQuery.of(context).size.width - 24;
    final int itemsOnScreen = (math.min(width, 818) / 56).ceil();

    final int toneSize = moreColors ? itemsOnScreen * 2 : itemsOnScreen;
    final int hueSize = moreColors ? 90 : 45;

    return ContrastHorizontalPicker(
      kind: kind,
      fetchHue: (Color c) => hsluvAlternatives(c, hueSize),
      fetchSat: (Color c, Color otherColor) =>
          hsluvTones(c, toneSize, 5, 100).convertToInterContrast(kind, otherColor),
      fetchLight: (Color c, Color otherColor) =>
          hsluvLightness(c, toneSize, 5, 90)
              .convertToInterContrast(kind, otherColor),
      hueTitle: hueStr,
      satTitle: satStr,
      lightTitle: lightStr,
      toneSize: toneSize,
      isFirst: isFirst,
    );
  }
}

class ContrastHorizontalPicker extends StatefulWidget {
  const ContrastHorizontalPicker({
    this.kind,
    this.fetchHue,
    this.fetchSat,
    this.fetchLight,
    this.hueTitle,
    this.satTitle,
    this.lightTitle,
    this.toneSize,
    this.isFirst,
  });

  final String kind;
  final bool isFirst;
  final List<Color> Function(Color) fetchHue;
  final List<InterColorWithContrast> Function(Color, Color) fetchSat;
  final List<InterColorWithContrast> Function(Color, Color) fetchLight;

  final int toneSize;
  final String hueTitle;
  final String satTitle;
  final String lightTitle;

  @override
  _ContrastHorizontalPickerState createState() =>
      _ContrastHorizontalPickerState();
}

class _ContrastHorizontalPickerState extends State<ContrastHorizontalPicker> {
  double opacity = 0.0;

  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        opacity = 1.0;
      });
    });
    super.initState();
  }

  double interval(double value, double min, double max) {
    return math.min(math.max(value, min), max);
  }

  List<InterColorWithContrast> parseHue(Color color, Color otherColor) {
    return widget.fetchHue(color).map((Color c) {
      final HSInterColor hsluv = HSInterColor.fromColor(c, widget.kind);
      final color = hsluv.toColor();
      return InterColorWithContrast(color, hsluv, otherColor);
    }).toList();
  }

  void contrastColorSelected(BuildContext context, Color color) {
    BlocProvider.of<ContrastColorBloc>(context)
        .add(CMoveColor(color, widget.isFirst));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContrastColorBloc, ContrastColorState>(
        builder: (BuildContext context, ContrastColorState state) {
      if (state is ContrastColorLoading) {
        return const Scaffold(body: Center(child: LoadingIndicator()));
      }

      final Color rgbColor = when({
        () => widget.isFirst: () => (state as ContrastColorLoaded).rgbColor1,
        () => !widget.isFirst: () => (state as ContrastColorLoaded).rgbColor2,
      });

      final Color otherColor = when({
        () => widget.isFirst: () => (state as ContrastColorLoaded).rgbColor2,
        () => !widget.isFirst: () => (state as ContrastColorLoaded).rgbColor1,
      });

      final contrast = calculateContrast(rgbColor, otherColor);

      final hue = parseHue(rgbColor, otherColor);
      final hueLen = hue.length;

      // in the ideal the world they could be calculated in the Bloc &/or in parallel.
      final List<InterColorWithContrast> tones =
          widget.fetchSat(rgbColor, otherColor);
      final List<InterColorWithContrast> values =
          widget.fetchLight(rgbColor, otherColor);

      final Color borderColor = (rgbColor.computeLuminance() > kLumContrast)
          ? Colors.black.withOpacity(0.40)
          : Colors.white.withOpacity(0.40);

      final Widget hueWidget = ContrastList(
        pageKey: widget.kind,
        title: widget.hueTitle,
        sectionIndex: 0,
        listSize: hueLen,
        isInfinite: true,
        colorsList: hue,
        buildWidget: (int index) {},
        onColorPressed: (Color c) => contrastColorSelected(context, c),
      );

      final satWidget = ContrastList(
        pageKey: widget.kind,
        title: widget.satTitle,
        sectionIndex: 1,
        listSize: widget.toneSize,
        colorsList: tones,
        onColorPressed: (Color c) => contrastColorSelected(context, c),
      );

      final valueWidget = ContrastList(
        pageKey: widget.kind,
        title: widget.lightTitle,
        sectionIndex: 2,
        listSize: widget.toneSize,
        colorsList: values,
        onColorPressed: (Color c) => contrastColorSelected(context, c),
      );

      final List<Widget> widgets = <Widget>[hueWidget, satWidget, valueWidget];

      final shape = RoundedRectangleBorder(
        side: BorderSide(color: borderColor),
        borderRadius: BorderRadius.circular(defaultRadius),
      );

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
          buttonTheme: ButtonThemeData(shape: shape),
          cardTheme: Theme.of(context).cardTheme.copyWith(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                shape: shape,
              ),
        ),
        child: Scaffold(
          backgroundColor: rgbColor,
          body: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 818),
            child: Flex(
              mainAxisAlignment: MainAxisAlignment.center,
              direction: Axis.vertical,
              children: <Widget>[
                const SizedBox(height: 8),
                AnimatedOpacity(
                  opacity: opacity,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeIn,
                  child: _UpperPart(
                      rgbColor, otherColor, contrast, widget.isFirst),
                ),
                Flex(
                  direction: Axis.vertical,
                  children: <Widget>[
                    const SizedBox(height: 8),
                    for (int i = 0; i < 3; i++) ...<Widget>[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: SizedBox(
                                // make items larger on iPad
                                height:
                                    MediaQuery.of(context).size.shortestSide <
                                            600
                                        ? 56
                                        : 64,
                                child: widgets[i],
                              ),
                            ),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 48,
                              child: Text(
                                HSInterColor.fromColor(rgbColor, widget.kind)
                                    .toPartialStr(i),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontFamily: "B612Mono", fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
//                if (widget.isFirst) const SizedBox(height: 16),

//                  AnimatedOpacity(
//                    opacity: opacity,
//                    duration: const Duration(milliseconds: 500),
//                    curve: Curves.easeIn,
//                    child: _BottomPart(
//                      rgbColor,
//                      otherColor,
//                      widget.kind,
//                      widget.isFirst,
//                    ),
//                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _UpperPart extends StatelessWidget {
  const _UpperPart(this.color, this.otherColor, this.contrast, this.isFirst);

  final Color otherColor;
  final Color color;
  final double contrast;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final checkIcon = Icon(
      FeatherIcons.checkCircle,
      color: otherColor,
    );

    final removeIcon = Icon(
      FeatherIcons.xCircle,
      color: otherColor,
    );

    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: otherColor,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        const SizedBox(width: 16),
        SizedBox(
          width: 56,
          child: Column(
            children: <Widget>[
              RichText(
                text: TextSpan(style: style, children: [
                  TextSpan(
                    text: contrast.toStringAsPrecision(3),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: ":1",
                    style: style.copyWith(
                      fontSize: 14,
                    ),
                  ),
                ]),
              ),
              Text(
                getContrastLetters(contrast),
                style: style.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              width: 1,
              height: 32,
              color: otherColor,
            ),
          ),
        ),
        _Buttons(color: color, otherColor: otherColor, isFirst: isFirst),
        const SizedBox(width: 16),

//        Row(
//          children: <Widget>[
//            if (contrast > 3.0) checkIcon else removeIcon,
//            const SizedBox(width: 8),
////                            Icon(
////                              Icons.wb_sunny,
////                              color: otherColor,
////                            ),
//            const SizedBox(width: 8),
//            Column(
//              children: <Widget>[
//                Text(
//                  "Large",
//                  style: TextStyle(
//                    // similar to H6
//                    fontSize: 18,
//                    fontWeight: FontWeight.w500,
//                    color: otherColor,
//                  ),
//                ),
//                Text("AA Large", style: style),
//              ],
//            ),
//          ],
//        ),
//        Row(
//          children: <Widget>[
//            if (contrast > 4.5) checkIcon else removeIcon,
//            const SizedBox(width: 8),
//            Column(
//              children: <Widget>[
//                Text(
//                  "Small",
//                  style: TextStyle(
//                    fontSize: 14,
//                    color: otherColor,
//                  ),
//                ),
//                Text("AA", style: style),
//              ],
//            ),
//          ],
//        ),
      ],
    );
  }
}

class _BottomPart extends StatelessWidget {
  const _BottomPart(this.color, this.otherColor, this.kind, this.isFirst);

  final Color color;
  final Color otherColor;
  final String kind;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Text(
            HSInterColor.fromColor(color, kind).toString(),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: "B612Mono",
            ),
          ),
          _Buttons(color: color, otherColor: otherColor, isFirst: isFirst),
        ],
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({this.color, this.otherColor, this.isFirst});

  final Color color;
  final Color otherColor;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        OutlineButton.icon(
          icon: Icon(
            FeatherIcons.search,
            size: 16,
          ),
          color: color,
          highlightedBorderColor: otherColor,
          borderSide: BorderSide(color: otherColor),
          label: Text(color.toHexStr()),
          onPressed: () {
//            showSlidersDialog(context, color, isFirst);
          },
          onLongPress: () {
            copyToClipboard(context, color.toHexStr());
          },
        ),
        const SizedBox(width: 16),
        MaterialButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
            side: BorderSide(
              color: otherColor,
              width: 1.0,
            ),
          ),
          highlightColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
          minWidth: 48,
          elevation: 0,
          child: Icon(
            FeatherIcons.shuffle,
            size: 16,
          ),
//          color: color,
          padding: EdgeInsets.zero,
          onPressed: () {
            BlocProvider.of<ContrastColorBloc>(context)
                .add(CMoveColor(shuffleColor(otherColor), isFirst));
          },
        ),
      ],
    );
  }
}