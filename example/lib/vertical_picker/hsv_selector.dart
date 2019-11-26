import 'package:flutter/material.dart';
import 'package:hsluvsample/color_with_inter.dart';
import 'package:hsluvsample/util/hsv_tiny.dart';

import 'vertical_picker_main.dart';

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
        ((MediaQuery.of(context).size.height - 56*4) / 56).ceil();

    final int toneSize = moreColors ? itemsOnScreen * 2 : itemsOnScreen;
    final int hueSize = moreColors ? 90 : 60;

    return HSGenericScreen(
      color: color,
      kind: kind,
      fetchHue: () => hsvAlternatives(color, hueSize),
      fetchSat: (Color c) =>
          hsvTones(c, toneSize, 0.05, 1.0).convertToInter(kind),
      fetchLight: (Color c) =>
          hsvValues(c, toneSize, 0.05, 1.0).convertToInter(kind),
      hueTitle: hueStr,
      satTitle: satStr,
      lightTitle: valueStr,
      toneSize: toneSize,
    );
  }
}
