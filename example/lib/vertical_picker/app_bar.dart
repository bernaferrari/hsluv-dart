import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hsluvsample/contrast/contrast_dialog.dart';
import 'package:hsluvsample/util/color_util.dart';
import 'package:hsluvsample/util/constants.dart';

class ColorSearchButton extends StatelessWidget {
  const ColorSearchButton({this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color onSurface =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: SizedBox(
        height: 36,
        child: OutlineButton.icon(
          icon: Icon(FeatherIcons.search, size: 16),
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
          borderSide: BorderSide(color: onSurface),
          highlightedBorderColor: onSurface,
          label: Text(color.toHexStr()),
          textColor: onSurface,
          onPressed: () {
            showSlidersDialog(context, color);
          },
        ),
      ),
    );
  }
}

class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({this.child, this.onPressed});

  final Function onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: RawMaterialButton(
        onPressed: null,
        child: child,
        shape: CircleBorder(
          side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
        elevation: 0.0,
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
    );
  }
}
