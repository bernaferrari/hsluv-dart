import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hsluvsample/blocs/multiple_contrast_color/multiple_contrast_color_bloc.dart';
import 'package:hsluvsample/blocs/multiple_contrast_color/multiple_contrast_color_event.dart';
import 'package:hsluvsample/blocs/multiple_contrast_color/multiple_contrast_color_state.dart';
import 'package:hsluvsample/contrast/inter_color_with_contrast.dart';
import 'package:hsluvsample/contrast/reorder_list.dart';
import 'package:hsluvsample/contrast/shuffle_color.dart';
import 'package:hsluvsample/hsinter.dart';
import 'package:hsluvsample/mdc/components.dart';
import 'package:hsluvsample/util/color_util.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:hsluvsample/util/hsluv_tiny.dart';
import 'package:hsluvsample/util/selected.dart';
import 'package:hsluvsample/widgets/loading_indicator.dart';

import '../util/constants.dart';
import '../widgets/update_color_dialog.dart';
import 'contrast_item.dart';
import 'contrast_list.dart';
import 'contrast_util.dart';
import 'info_screen.dart';

class MultipleContrastScreen extends StatefulWidget {
  const MultipleContrastScreen();

  @override
  _MultipleContrastScreenState createState() => _MultipleContrastScreenState();
}

class _MultipleContrastScreenState extends State<MultipleContrastScreen> {
  bool contrastMode = true;

  int currentSegment = 0;

  void onValueChanged(int newValue) {
    setState(() {
      currentSegment = newValue;
      contrastMode = currentSegment == 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MultipleContrastColorBloc, MultipleContrastColorState>(
        builder:
            (BuildContext builderContext, MultipleContrastColorState state) {
      if (state is MultipleContrastColorLoading) {
        return const Scaffold(body: Center(child: LoadingIndicator()));
      }

      final list = (state as MultipleContrastColorLoaded).colorsList;

      ColorScheme colorScheme;

      if (list[0].rgbColor.computeLuminance() > kLumContrast) {
        colorScheme = ColorScheme.light(
          primary: list[0].rgbColor,
          surface: list[0].rgbColor,
        );
      } else {
        colorScheme = ColorScheme.dark(
          primary: list[0].rgbColor,
          surface: list[0].rgbColor,
        );
      }

      return Theme(
        data: ThemeData.from(
          colorScheme: colorScheme,
          textTheme: const TextTheme(
            caption: TextStyle(fontFamily: "B612Mono"),
            button: TextStyle(fontFamily: "B612Mono"),
          ),
        ).copyWith(
          buttonTheme: Theme.of(context).buttonTheme.copyWith(
                  shape: RoundedRectangleBorder(
                side: BorderSide(color: list[0].rgbColor),
                borderRadius: BorderRadius.circular(defaultRadius),
              )),
          cardTheme: Theme.of(context).cardTheme,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Contrast Compare"),
            actions: <Widget>[
              IconButton(
                icon: Icon(FeatherIcons.list),
                onPressed: () => showReorderDialog(builderContext, list),
              )
            ],
            bottom: PreferredSize(
              preferredSize: const Size(500, 56),
              child: Container(
                width: 500,
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16,
                  top: 16,
                  bottom: 12,
                ),
                child: CupertinoSlidingSegmentedControl<int>(
                  backgroundColor: colorScheme.onSurface.withOpacity(0.20),
                  thumbColor: compositeColors(
                    colorScheme.background,
                    list[0].rgbColor,
                    kVeryTransparent,
                  ),
                  children: const <int, Widget>{
                    0: Text('Contrast'),
                    1: Text('Info'),
                  },
                  onValueChanged: onValueChanged,
                  groupValue: currentSegment,
                ),
              ),
            ),
          ),
          body: contrastMode ? buildFlex(list) : InfoScreen(list),
        ),
      );
    });
  }

  Widget buildFlex(List<ContrastedColor> colorsList) {
    const bool more = false;
    final interListOfLists = <List<InterColorWithContrast>>[];

    for (var element in colorsList) {
      final interList = <InterColorWithContrast>[];
      for (int i = -10; i < 15; i += 5) {
        final luv = HSInterColor.fromColor(element.rgbColor, "HSLuv");
        // if lightness becomes 0 or 100 the hue value might be lost
        // because app is always converting HSLuv to RGB and vice-versa.
        final updatedLuv =
            luv.withLightness(interval(luv.lightness + i, 5.0, 95.0));

        interList.add(
          InterColorWithContrast(
            updatedLuv.toColor(),
            updatedLuv,
            colorsList[0].rgbColor,
          ),
        );
      }
      interListOfLists.add(interList);
    }

    return ListView.builder(
      key: const PageStorageKey("ContrastCompareKey"),
      itemCount: colorsList.length,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return HSLuvSelector2(
            index: index,
            moreColors: more,
            colorsMap: colorsList,
          );
        } else {
          return Container(
            padding: const EdgeInsets.only(top: 12, bottom: 16),
            color: colorsList[index].rgbColor,
            child: Column(
              children: <Widget>[
                _UpperPart(
                  colorsList[index].rgbColor,
                  colorsList[0].rgbColor,
                  colorsList[index].contrast,
                  index,
                  colorsList,
                ),
                _Minimized("HSLuv", index, interListOfLists[index]),
              ],
            ),
          );
        }
      },
    );
  }

  Future<void> showReorderDialog(
      BuildContext builderContext, List<ContrastedColor> list) async {
    final dynamic result = await showDialog<dynamic>(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text("Drag to reorder"),
            contentPadding: const EdgeInsets.only(top: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Card(
              clipBehavior: Clip.antiAlias,
              margin: EdgeInsets.zero,
              color: compositeColors(
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.primary,
                0.20,
              ),
              child: ReorderList(list),
            ),
          );
        });

    if (result != null) {
      BlocProvider.of<MultipleContrastColorBloc>(builderContext)
          .add(MultipleLoadInit(result));
    }
  }
}

class HSLuvSelector2 extends StatelessWidget {
  const HSLuvSelector2({
    this.moreColors = false,
    this.index,
    this.colorsMap,
  });

  // maximum number of items
  final bool moreColors;

  final List<ContrastedColor> colorsMap;

  final int index;

  @override
  Widget build(BuildContext context) {
    const String kind = hsluvStr;

    // maximum number of items
    final double width = MediaQuery.of(context).size.width - 24;
    final int itemsOnScreen = (math.min(width, 818) / 56).ceil();

    final int toneSize = 19; //moreColors ? itemsOnScreen * 2 : itemsOnScreen;
    final int hueSize = moreColors ? 90 : 45;

    return ContrastHorizontalPicker(
      kind: kind,
      isShrink: true,
      fetchHue: (Color c) => hsluvAlternatives(c, hueSize),
      fetchSat: (Color c, Color otherColor) => hsluvTones(c, toneSize, 10, 100)
          .convertToInterContrast(kind, otherColor),
      fetchLight: (Color c, Color otherColor) =>
          hsluvLightness(c, toneSize, 5, 95)
              .convertToInterContrast(kind, otherColor),
      hueTitle: hueStr,
      satTitle: satStr,
      lightTitle: lightStr,
      toneSize: toneSize,
      colorsList: colorsMap,
      index: index,
    );
  }
}

class ContrastHorizontalPicker extends StatelessWidget {
  const ContrastHorizontalPicker({
    this.kind,
    this.fetchHue,
    this.fetchSat,
    this.fetchLight,
    this.hueTitle,
    this.satTitle,
    this.lightTitle,
    this.toneSize,
    this.index,
    this.isShrink,
    this.colorsList,
  });

  final String kind;
  final bool isShrink;
  final int index;
  final List<ContrastedColor> colorsList;
  final List<Color> Function(Color) fetchHue;
  final List<InterColorWithContrast> Function(Color, Color) fetchSat;
  final List<InterColorWithContrast> Function(Color, Color) fetchLight;

  final int toneSize;
  final String hueTitle;
  final String satTitle;
  final String lightTitle;

  double interval(double value, double min, double max) {
    return math.min(math.max(value, min), max);
  }

  List<InterColorWithContrast> parseHue(Color color, Color otherColor) {
    return fetchHue(color).map((Color c) {
      final HSInterColor hsluv = HSInterColor.fromColor(c, kind);
      final color = hsluv.toColor();
      return InterColorWithContrast(color, hsluv, otherColor);
    }).toList();
  }

  void contrastColorSelected(BuildContext context, Color color) {
    BlocProvider.of<MultipleContrastColorBloc>(context)
        .add(MCMoveColor(color, index));
  }

  @override
  Widget build(BuildContext context) {
    final Color rgbColor = colorsList[index].rgbColor;

    final Color otherColor = colorsList[0].rgbColor;

    final contrast = colorsList[index].contrast;

    final List<InterColorWithContrast> values =
        fetchLight(rgbColor, otherColor);

    final Color borderColor = (rgbColor.computeLuminance() > kLumContrast)
        ? Colors.black.withOpacity(0.40)
        : Colors.white.withOpacity(0.40);

    final List<Widget> widgets = <Widget>[];

    final hue = parseHue(rgbColor, otherColor);
    final hueLen = hue.length;

    // in the ideal the world they could be calculated in the Bloc &/or in parallel.
    final List<InterColorWithContrast> tones = fetchSat(rgbColor, otherColor);

    final Widget hueWidget = ContrastList(
      pageKey: kind,
      title: hueTitle,
      sectionIndex: 0,
      listSize: hueLen,
      isInfinite: true,
      colorsList: hue,
      isFirst: index == 0,
      buildWidget: (int index) {},
      onColorPressed: (Color c) => contrastColorSelected(context, c),
    );
    widgets.add(hueWidget);

    final satWidget = ContrastList(
      pageKey: kind,
      title: satTitle,
      sectionIndex: 1,
      listSize: toneSize,
      isFirst: index == 0,
      colorsList: tones,
      onColorPressed: (Color c) => contrastColorSelected(context, c),
    );
    widgets.add(satWidget);

    final valueWidget = ContrastList(
      pageKey: kind,
      title: lightTitle,
      sectionIndex: 2,
      isFirst: index == 0,
      listSize: toneSize,
      colorsList: values,
      onColorPressed: (Color c) => contrastColorSelected(context, c),
    );
    widgets.add(valueWidget);

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
      child: Container(
        color: rgbColor,
        padding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 818),
          child: Flex(
            mainAxisAlignment: MainAxisAlignment.center,
            direction: Axis.vertical,
            children: <Widget>[
              _UpperPart(rgbColor, otherColor, contrast, index, colorsList),
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
                                  MediaQuery.of(context).size.shortestSide < 600
                                      ? 56
                                      : 64,
                              child: widgets[i],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            child: Text(
                              HSInterColor.fromColor(rgbColor, kind)
                                  .toPartialStr((index == 0) ? i : 2),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "B612Mono",
                                fontSize: 12,
                                color: contrastingColor(rgbColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Minimized extends StatelessWidget {
  const _Minimized(this.kind, this.index, this.hsInter);

  final String kind;
  final int index;
  final List<InterColorWithContrast> hsInter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (int i = 0; i < hsInter.length; i++)
              SizedBox(
                width: 56,
                height: 56,
                child: ContrastItem(
                  kind: kind,
                  color: hsInter[i],
                  contrast: hsInter[i].contrast,
                  compactText: false,
                  category: "Lightness",
                  onPressed: () {
                    BlocProvider.of<MultipleContrastColorBloc>(context)
                        .add(MCMoveColor(hsInter[i].color, index));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpperPart extends StatelessWidget {
  const _UpperPart(
      this.color, this.otherColor, this.contrast, this.index, this.list);

  final Color otherColor;
  final Color color;
  final double contrast;
  final int index;
  final List<ContrastedColor> list;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: otherColor,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const SizedBox(width: 16),
        if (index != 0)
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
          )
        else
          Text(
            "Main Color",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        const SizedBox(width: 16),
//        Expanded(
//          child: Center(
//            child: Container(
//              width: 0,
//              height: 32,
//              color: otherColor,
//            ),
//          ),
//        ),
        _Buttons(
          color: color,
          otherColor: (index == 0)
              ? Theme.of(context).colorScheme.onSurface
              : otherColor,
          index: index,
          list: list,
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({this.color, this.otherColor, this.index, this.list});

  final Color color;
  final Color otherColor;
  final int index;
  final List<ContrastedColor> list;

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
            showSlidersDialog(context, color, index);
          },
          onLongPress: () {
            copyToClipboard(context, color.toHexStr());
          },
        ),
        const SizedBox(width: 16),
//        if (index == 0)
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
          padding: EdgeInsets.zero,
          onPressed: () {
            BlocProvider.of<MultipleContrastColorBloc>(context).add(
              MCMoveColor(
                getShuffleColor(),
                index,
              ),
            );
          },
        ),
//        if (index != 0) const SizedBox(width: 16),
//        if (index != 0)
//          MaterialButton(
//            shape: RoundedRectangleBorder(
//              borderRadius: BorderRadius.circular(defaultRadius),
//              side: BorderSide(
//                color: otherColor,
//                width: 1.0,
//              ),
//            ),
//            highlightColor:
//                Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
//            minWidth: 48,
//            elevation: 0,
//            child: Icon(
//              FeatherIcons.maximize2,
//              size: 16,
//            ),
//            padding: EdgeInsets.zero,
//            onPressed: () => showReorderDialog(context, color, otherColor),
//          ),
      ],
    );
  }
}

class SelectorDialog extends StatelessWidget {
  const SelectorDialog(this.color, this.otherColor, this.list);

  final Color color;
  final Color otherColor;
  final List<ContrastedColor> list;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          HSLuvSelector2(
            index: 1,
            moreColors: false,
            colorsMap: list,
          ),
        ],
      ),
    );
  }
}
