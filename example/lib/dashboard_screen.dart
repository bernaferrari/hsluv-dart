import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hsluvsample/blocs/blocs.dart';
import 'package:hsluvsample/contrast/shuffle_color.dart';
import 'package:hsluvsample/single_color_blind.dart';
import 'package:hsluvsample/util/selected.dart';
import 'package:hsluvsample/util/tiny_color.dart';
import 'package:hsluvsample/util/when.dart';
import 'package:hsluvsample/widgets/loading_indicator.dart';
import 'package:infinite_listview/infinite_listview.dart';

import 'contrast/inter_color_with_contrast.dart';
import 'util/color_blindness.dart';

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

// sources:
// https://www.color-blindness.com/
// https://www.color-blindness.com/category/tools/
// https://en.wikipedia.org/wiki/Color_blindness
// https://en.wikipedia.org/wiki/Dichromacy
List<ColorWithBlind> retrieveColorBlindList(Color color) {
  const m = "of males";
  const f = "of females";
  const p = "of population";

  return [
    ColorWithBlind(color, "None", "default"),
    ColorWithBlind(protanomaly(color), "Protanomaly", "1% $m, 0.01% $f"),
    ColorWithBlind(deuteranomaly(color), "Deuteranomaly", "6% $m, 0.4% $f"),
    ColorWithBlind(tritanomaly(color), "Tritanomaly", "0.01% $p"),
    ColorWithBlind(protanopia(color), "Protanopia", "1% $m"),
    ColorWithBlind(deuteranopia(color), "Deuteranopia", "1% $m"),
    ColorWithBlind(tritanopia(color), "Tritanopia", "less than 1% $p"),
    ColorWithBlind(achromatopsia(color), "Achromatopsia", "0.003% $p"),
    ColorWithBlind(achromatomaly(color), "Achromatomaly", "0.001% $p"),
  ];
}

ColorWithBlind getColorBlindFromIndex(Color color, int i) {
  const m = "of males";
  const f = "of females";
  const p = "of population";

  return when({
    () => i == 0: () => null,
    () => i == 1: () =>
        ColorWithBlind(protanomaly(color), "Protanomaly", "1% $m, 0.01% $f"),
    () => i == 2: () =>
        ColorWithBlind(deuteranomaly(color), "Deuteranomaly", "6% $m, 0.4% $f"),
    () => i == 3: () =>
        ColorWithBlind(tritanomaly(color), "Tritanomaly", "0.01% $p"),
    () => i == 4: () =>
        ColorWithBlind(protanopia(color), "Protanopia", "1% $m"),
    () => i == 5: () =>
        ColorWithBlind(deuteranopia(color), "Deuteranopia", "1% $m"),
    () => i == 6: () =>
        ColorWithBlind(tritanopia(color), "Tritanopia", "less than 1% $p"),
    () => i == 7: () =>
        ColorWithBlind(achromatopsia(color), "Achromatopsia", "0.003% $p"),
    () => i == 8: () =>
        ColorWithBlind(achromatomaly(color), "Achromatomaly", "0.001% $p"),
  });
}

String generateBlindName(int i) {
  return when({
    () => i == 1: () => "Protanomaly",
    () => i == 2: () => "Deuteranomaly",
    () => i == 3: () => "Tritanomaly",
    () => i == 4: () => "Protanopia",
    () => i == 5: () => "Deuteranopia",
    () => i == 6: () => "Tritanopia",
    () => i == 7: () => "Achromatopsia",
    () => i == 8: () => "Achromatomaly",
  });
}
