import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../util/color_util.dart';
import '../util/constants.dart';
import '../widgets/update_color_dialog.dart';

class ColorSearchButton extends StatelessWidget {
  const ColorSearchButton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color onSurface =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
      child: SizedBox(
        height: 36,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
            side: BorderSide(color: onSurface),
          ),
          icon: Icon(
            FeatherIcons.search,
            size: 16,
            color: onSurface,
          ),
          label: Text(
            color.toHexStr(),
            style: Theme.of(context)
                .textTheme
                .bodyText2!
                .copyWith(color: onSurface),
          ),
          onPressed: () {
            showSlidersDialog(context, color);
          },
        ),
      ),
    );
  }
}

class OutlinedIconButton extends StatelessWidget {
  const OutlinedIconButton({
    required this.child,
    this.borderColor,
    this.onPressed,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: CircleBorder(),
          side: BorderSide(
            color: borderColor ??
                Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          primary: Theme.of(context).colorScheme.onSurface,
        ),
        child: child,
        onPressed: onPressed,
      ),
    );
  }
}
