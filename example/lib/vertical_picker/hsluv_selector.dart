import 'package:flutter/material.dart';
import 'package:hsluvsample/color_with_inter.dart';
import 'package:hsluvsample/util/hsluv_tiny.dart';

import 'vertical_picker_main.dart';

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
        ((MediaQuery.of(context).size.height - 56*4) / 56).ceil();

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
