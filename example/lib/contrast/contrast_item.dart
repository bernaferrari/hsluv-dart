import 'package:flutter/material.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:hsluvsample/util/when.dart';

import '../hsinter.dart';
import 'color_with_contrast.dart';
import 'contrast_util.dart';

class ContrastItem extends StatelessWidget {
  const ContrastItem({
    this.color,
    this.onPressed,
    this.contrast,
    this.compactText = true,
    this.category = "",
    this.kind,
  });

  final ColorWithContrast color;
  final Function onPressed;
  final bool compactText;
  final double contrast;
  final String category;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final Color textColor = (color.lum < kLumContrast)
        ? Colors.white.withOpacity(0.87)
        : Colors.black87;

    final HSInterColor inter = color.inter;

    final String writtenValue = when<String>({
      () => category == hueStr: () => inter.hue.round().toString(),
      () => category == satStr: () => "${inter.outputSaturation()}",
      () => category == lightStr || category == valueStr: () =>
          "${inter.outputLightness()}",
    });

    final Widget cornerText = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          writtenValue,
          style: Theme.of(context).textTheme.caption.copyWith(color: textColor),
        ),
        Text(
          contrast.toStringAsPrecision(3),
          style: Theme.of(context)
              .textTheme
              .caption
              .copyWith(fontSize: 10, color: textColor),
        ),
        Text(
          getContrastLetters(contrast),
          style: Theme.of(context)
              .textTheme
              .caption
              .copyWith(fontSize: 8, color: textColor),
        )
      ],
    );

    return SizedBox(
      width: 56,
      child: MaterialButton(
        elevation: 0,
        padding: EdgeInsets.zero,
        color: color.color,
        shape: const RoundedRectangleBorder(),
        onPressed: onPressed,
        child: cornerText,
      ),
    );
  }
}