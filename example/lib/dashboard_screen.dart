import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluvsample/blocs/blocs.dart';
import 'package:hsluvsample/util/selected.dart';
import 'package:hsluvsample/util/tiny_color.dart';
import 'package:hsluvsample/widgets/loading_indicator.dart';
import 'package:infinite_listview/infinite_listview.dart';

import 'util/color_blindness.dart';
import 'contrast/color_with_contrast.dart';

class HorizontalAlternative extends StatelessWidget {
  const HorizontalAlternative({this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final alternativeCount = hsluvHueToneVariation(color, 50);
    final altLighter = hsluvHueToneVariation(color, 50, 7);
    final altDarker = hsluvHueToneVariation(color, 50, -7);

    return SizedBox(
      height: 3 * 36.0 + 3,
      child: InfiniteListView.builder(
        key: const PageStorageKey("AlternativeDashboard"),
        itemBuilder: (context, index) {
          final int realIndex = index.abs() % alternativeCount.length;

          return Column(
            children: <Widget>[
              ColoredButton(altDarker[realIndex], realIndex, altDarker.length),
              ColoredButton(alternativeCount[realIndex], realIndex,
                  alternativeCount.length),
              ColoredButton(
                  altLighter[realIndex], realIndex, altLighter.length),
            ],
          );
        },
        scrollDirection: Axis.horizontal,
      ),
    );
  }
}

class ColorBlindSection extends StatelessWidget {
  const ColorBlindSection({this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorWithBlind = retrieveColorBlind(color);
    return LayoutBuilder(
      builder: (context, builder) {
        const numOfItems = 4; //(builder.maxWidth / 56).floor();

        return Wrap(
          children: <Widget>[
            for (String key in colorWithBlind.keys)
              for (ColorWithBlind item in colorWithBlind[key])
                ColoredBlindButton(
                  item,
                  width: builder.maxWidth / numOfItems,
                )
          ],
        );
      },
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen();

  @override
  Widget build(BuildContext context) {
    final double itemWidth = MediaQuery.of(context).size.width;
    const double itemHeight = 56;

    return BlocBuilder<SliderColorBloc, SliderColorState>(
        builder: (BuildContext context, SliderColorState state) {
      if (state is SliderColorLoading) {
        return const Scaffold(body: Center(child: LoadingIndicator()));
      }

      final color = (state as SliderColorLoaded).rgbColor;

      return ListView(key: const PageStorageKey("dashboard"), children: <
          Widget>[
//            Padding(
//              padding: const EdgeInsets.only(left: 24.0, top: 16, bottom: 8),
//              child: Text("Alternative", style: Theme.of(context).textTheme.title),
//            ),
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16.0, top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Alternative",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(fontFamily: "B612Mono"),
              ),
              FlatButton(
                onPressed: () {
//                      Navigator.push<dynamic>(
//                        context,
//                        MaterialPageRoute<dynamic>(
//                          builder: (context) => ColorDetailsScreen(kind: key),
//                        ),
//                      );
                },
//                highlightedBorderColor: Colors.white,
                child: const Text("SEE MORE"),
              ),
            ],
          ),
        ),
        HorizontalAlternative(color: color),
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16.0, top: 16, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Contrast",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(fontFamily: "B612Mono"),
              ),
              FlatButton(
                onPressed: () {
//                      Navigator.push<dynamic>(
//                        context,
//                        MaterialPageRoute<dynamic>(
//                          builder: (context) => ColorDetailsScreen(kind: key),
//                        ),
//                      );
                },
//                highlightedBorderColor: Colors.white,
                child: const Text("SEE MORE"),
              ),
            ],
          ),
        ),

//            Row(
//              children: <Widget>[
//                Center(
//                  child: Container(
//                    width: 180,
//                    height: 80,
//                    child: RaisedButton(
//                      onPressed: () {},
//                      child: Stack(
//                        children: <Widget>[
//                          Wrap(
//                            children: <Widget>[
//                              for (int i = 0;
//                              i < currentState.allContrast["Fail"].length;
//                              i++)
//                                Container(color: currentState.allContrast["Fail"][i].color, height: 24, width: 24,)
//                            ],
//                          ),
//                          Center(child: Text("FAIL", style: Theme.of(context).textTheme.title,)),
//                        ],
//                      ),
//                    ),
//                  ),
//                ),
//                Center(
//                  child: Container(
//                    width: 180,
//                    height: 80,
//                    child: RaisedButton(
//                      onPressed: () {},
//                      child: Stack(
//                        children: <Widget>[
//                          Wrap(
//                            children: <Widget>[
//                              for (int i = 0;
//                              i < currentState.allContrast["AA+"].length;
//                              i++)
//                                Padding(
//                                  padding: const EdgeInsets.all(0.2),
//                                  child: Container(color: currentState.allContrast["AA+"][i].color, height: 35, width: 35),
//                                )
//                            ],
//                          ),
//                          Center(child: Text("AA+", style: Theme.of(context).textTheme.title,)),
//                        ],
//                      ),
//                    ),
//                  ),
//                ),
//                Center(
//                  child: Container(
//                    width: 180,
//                    height: 80,
//                    child: RaisedButton(
//                      onPressed: () {},
//                      child: Stack(
//                        children: <Widget>[
//                          Wrap(
//                            children: <Widget>[
//                              for (int i = 0;
//                              i < currentState.allContrast["AA"].length;
//                              i++)
//                                Padding(
//                                  padding: const EdgeInsets.all(0.2),
//                                  child: Container(color: currentState.allContrast["AA"][i].color, height: 96, width: 8,),
//                                )
//                            ],
//                          ),
//                          Center(child: Text("AA", style: Theme.of(context).textTheme.title,)),
//                        ],
//                      ),
//                    ),
//                  ),
//                ),
//                Center(
//                  child: Container(
//                    width: 180,
//                    height: 80,
//                    child: RaisedButton(
//                      onPressed: () {},
//                      child: Stack(
//                        children: <Widget>[
//                          Wrap(
//                            children: <Widget>[
//                              for (int i = 0;
//                              i < currentState.allContrast["AAA"].length;
//                              i++)
//                                Padding(
//                                  padding: const EdgeInsets.all(0.2),
//                                  child: Container(color: currentState.allContrast["AAA"][i].color, height: 6, width: 180,),
//                                )
//                            ],
//                          ),
//                          Center(child: Text("AAA", style: Theme.of(context).textTheme.title,)),
//                        ],
//                      ),
//                    ),
//                  ),
//                ),
//
//              ],
//            ),

//            SizedBox(
//              height: 4 * itemHeight,
//              child: ListView.builder(
//                physics: const BouncingScrollPhysics(),
//                itemCount: maxContrastItemsLen,
//                key: const PageStorageKey("ContrastDashboard"),
//                itemBuilder: (context, index) {
//                  final int realIndex = index - 1;
//
//                  return (index == 0)
//                      ? Padding(
//                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                    child: Column(
//                      mainAxisAlignment: MainAxisAlignment.spaceAround,
//                      crossAxisAlignment: CrossAxisAlignment.start,
//                      children: const <Widget>[
//                        Text(
//                          "Fail",
//                          style: TextStyle(fontFamily: "B612Mono"),
//                        ),
//                        Text(
//                          "AA+",
//                          style: TextStyle(fontFamily: "B612Mono"),
//                        ),
//                        Text(
//                          "AA",
//                          style: TextStyle(fontFamily: "B612Mono"),
//                        ),
//                        Text(
//                          "AAA",
//                          style: TextStyle(fontFamily: "B612Mono"),
//                        ),
//                      ],
//                    ),
//                  )
//                      : Padding(
//                    padding: (realIndex == 0)
//                        ? const EdgeInsets.only(left: 12.0)
//                        : (realIndex == maxContrastItemsLen - 2)
//                        ? const EdgeInsets.only(right: 12.0)
//                        : EdgeInsets.zero,
//                    child: Column(
//                      children: <Widget>[
//                        colorContrast(
//                            currentState.allContrast["Fail"], realIndex),
//                        colorContrast(
//                            currentState.allContrast["AA+"], realIndex),
//                        colorContrast(
//                            currentState.allContrast["AA"], realIndex),
//                        colorContrast(
//                            currentState.allContrast["AAA"], realIndex),
//                      ],
//                    ),
//                  );
//                },
//                scrollDirection: Axis.horizontal,
//              ),
//            ),
        const Divider(),
        Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16.0, top: 0, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Color Blindness",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .title
                    .copyWith(fontFamily: "B612Mono"),
              ),
              OutlineButton(
                onPressed: () {
//                      Navigator.push<dynamic>(
//                        context,
//                        MaterialPageRoute<dynamic>(
//                          builder: (context) => ColorDetailsScreen(kind: key),
//                        ),
//                      );
                },
                highlightedBorderColor: Colors.white,
                child: const Text("SEE MORE"),
              ),
            ],
          ),
        ),
        ColorBlindSection(color: color),
      ]);
    });
  }
}

Widget colorContrast(List<ColorWithContrast> allContrast, int index) {
  const itemWidth = 48.0;
  const itemHeight = 40.0; // 36 + 4 of padding

  final len = allContrast.length;

  if (len - 1 < index) {
    return const SizedBox(width: itemWidth, height: itemHeight);
  } else {
    return ColoredButton(allContrast[index].color, index, len - 1);
  }
}

class ColoredBlindButton extends StatelessWidget {
  const ColoredBlindButton(this.colorWithBlind, {this.width = 48});

  final ColorWithBlind colorWithBlind;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: MaterialButton(
        padding: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(),
        child: Text(
          colorWithBlind.affects.substring(0, 6),
          //colorWithBlind.name[0],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: (BlocProvider.of<SliderColorBloc>(context).state
                    as SliderColorLoaded)
                .rgbColor,
          ),
        ),
        color: colorWithBlind.color,
        onPressed: () {
          colorSelected(context, colorWithBlind.color);
        },
      ),
    );
  }
}

class ColoredButton extends StatelessWidget {
  const ColoredButton(this.color, this.index, this.lastIndex);

  final Color color;
  final int index;
  final int lastIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 0.5),
      child: SizedBox(
        width: 48,
        height: 36,
        child: MaterialButton(
          padding: EdgeInsets.zero,
          elevation: 0,
          shape: const RoundedRectangleBorder(),
          color: color,
          onPressed: () {
            colorSelected(context, color);
          },
        ),
      ),
    );
  }
}

// sources:
// https://www.color-blindness.com/
// https://www.color-blindness.com/category/tools/
// https://en.wikipedia.org/wiki/Color_blindness
// https://en.wikipedia.org/wiki/Dichromacy
Map<String, List<ColorWithBlind>> retrieveColorBlind(Color color) {
  const m = "of males";
  const f = "of females";
  const p = "of population";

  return {
    "Trichromacy": [
      ColorWithBlind(protanomaly(color), "Protanomaly", "1% $m, 0.01% $f"),
      ColorWithBlind(deuteranomaly(color), "Deuteranomaly", "6% $m, 0.4% $f"),
      ColorWithBlind(tritanomaly(color), "Tritanomaly", "0.01% $p"),
    ],
    "Dichromacy": [
      ColorWithBlind(protanopia(color), "Protanopia", "1% $m"),
      ColorWithBlind(deuteranopia(color), "Deuteranopia", "1% $m"),
      ColorWithBlind(tritanopia(color), "Tritanopia", "less than 1% $p"),
    ],
    "Monochromacy": [
      ColorWithBlind(achromatopsia(color), "Achromatopsia", "0.003% $p"),
      ColorWithBlind(achromatomaly(color), "Achromatomaly", "0.001% $p"),
    ],
  };
}

class ColorWithBlind {
  ColorWithBlind(this.color, this.name, this.affects);

  final Color color;
  final String name;
  final String affects;
}
