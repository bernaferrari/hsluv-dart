import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hsluvsample/hsinter.dart';
import 'package:hsluvsample/util/color_util.dart';

extension ListConversion<T> on List<Color> {
  List<ColorWithInter> convertToInter(String kind) =>
      map((Color c) => ColorWithInter(c, HSInterColor.fromColor(c, kind)))
          .toList();
}

class ColorWithInter {
  ColorWithInter(this.color, this.inter)
      : lum = color.computeLuminance(),
        colorHex = color.toHexStr();

  final Color color;
  final HSInterColor inter;
  final String colorHex;
  final double lum;
}
