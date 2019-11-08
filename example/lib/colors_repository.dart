import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material/util/color_util.dart';
import 'package:material/util/constants.dart';
import 'util/tiny_color.dart';

class ColorsRepository {
  Future<Map<String, List<ColorWithLum>>> retrieveColorAlternative(
    Color color,
  ) async {
    return {
      "Monochromatic": convertList(monoColorSteps(color, 12, 0.03)),
      "nTrad": convertList(nTrad(color)),
      "Alternative": convertList(alternative(color, 12, 6)),
      "Tones": convertList(tones(color)),
      "Darker Shades": convertList(darkShade(color, 12, 0.03, 0.05)),
      "Brighter Shades": convertList(brightShade(color, 12, 0.03)),
    };
  }

  Future<List<ColorWithContrast>> customRetrieveColorsFromList(
      Color color, List<String> list, double ratio) async {
    final newList =
        list.map((f) => ColorWithContrast(Color(int.parse("0xFF$f")), color));

    if (ratio < 3) {
      return newList.where((f) => f.contrast < ratio).toList();
    }

    return newList.where((f) => f.contrast > ratio).toList();
  }

  Future<List<ColorWithContrast>> retrieveColorsFromList(
    Color color,
    List<String> list,
  ) async {
    return list
        .map((f) => ColorWithContrast(Color(int.parse("0xFF$f")), color))
        .where((f) => f.contrast > 4.5)
        .toList();
  }
}

double calculateContrast(Color color1, Color color2) {
  final double colorFirstLum = color1.computeLuminance();
  final double colorSecondLum = color2.computeLuminance();

  final double l1 = min(colorFirstLum, colorSecondLum);
  final double l2 = max(colorFirstLum, colorSecondLum);

  return 1 / ((l1 + 0.05) / (l2 + 0.05));
}

List<ColorWithLum> convertList(List<Color> list) {
  return list.map((Color c) => ColorWithLum(c)).toList();
}

extension ListConversion<T> on List<Color> {
  List<ColorWithLum> convertList() =>
      map((Color c) => ColorWithLum(c)).toList();
}

class ColorWithBlind {
  ColorWithBlind(this.color, this.name, this.affects);

  final Color color;
  final String name;
  final String affects;
}

class ColorWithLum {
  ColorWithLum(this.color)
      : lum = color.computeLuminance(),
        colorHex = colorToHexStr(color);

  final Color color;
  final String colorHex;
  final double lum;
}

class ColorWithContrast {
  ColorWithContrast(this.color, Color color2, [this.name = ""])
      : lum = color.computeLuminance(),
        contrast = calculateContrast(color, color2);

  final Color color;
  final String name;
  final double contrast;
  final double lum;
}
