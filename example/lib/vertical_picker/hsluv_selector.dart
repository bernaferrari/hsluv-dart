import 'package:flutter/material.dart';
import 'package:hsluv/hsluvcolor.dart';

import '../color_with_inter.dart';
import '../hsinter.dart';
import '../util/hsinter_tiny.dart';
import 'vertical_picker_main.dart';

class HSLuvSelector extends StatelessWidget {
  const HSLuvSelector({required this.color, this.moreColors = false, Key? key})
      : super(key: key);

  // initial color
  final HSLuvColor color;

  final bool moreColors;

  @override
  Widget build(BuildContext context) {
    const kind = HSInterType.hsluv;

    // maximum number of items
    final int itemsOnScreen =
        ((MediaQuery.of(context).size.height - 56 * 4) / 56).ceil();

    final int toneSize = moreColors ? itemsOnScreen * 2 : itemsOnScreen;
    final int hueSize = moreColors ? 90 : 45;

    final inter = HSInterColor.fromHSLuv(color);

    return HSGenericScreen(
      color: inter,
      kind: kind,
      fetchHue: () =>
          hsinterAlternatives(inter, hueSize).convertToColorWithInter(),
      fetchSat: () =>
          hsinterTones(inter, toneSize, 0, 100).convertToColorWithInter(),
      fetchLight: () =>
          hsinterLightness(inter, toneSize, 0, 100).convertToColorWithInter(),
      hueTitle: hueStr,
      satTitle: satStr,
      lightTitle: lightStr,
      toneSize: toneSize,
    );
  }
}
