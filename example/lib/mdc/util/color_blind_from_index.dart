import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hsluvsample/blocs/blocs.dart';
import 'package:hsluvsample/contrast/shuffle_color.dart';
import 'package:hsluvsample/screens/single_color_blindness.dart';
import 'package:hsluvsample/util/selected.dart';
import 'package:hsluvsample/util/tiny_color.dart';
import 'package:hsluvsample/util/when.dart';
import 'package:hsluvsample/widgets/loading_indicator.dart';
import 'package:infinite_listview/infinite_listview.dart';

import '../../contrast/inter_color_with_contrast.dart';
import '../../util/color_blindness.dart';

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
