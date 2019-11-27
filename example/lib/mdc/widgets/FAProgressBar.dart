import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FAProgressBar extends StatelessWidget {
  const FAProgressBar({
    Key key,
    this.currentValue = 0,
    this.maxValue = 100,
    this.size = 30,
    this.direction = Axis.horizontal,
    this.verticalDirection = VerticalDirection.down,
    this.borderRadius = 8,
    this.borderColor = const Color(0xFFFA7268),
    this.borderWidth = 0.2,
    this.backgroundColor = const Color(0x00FFFFFF),
    this.progressColor = const Color(0xFFFA7268),
    this.changeColorValue,
    this.changeProgressColor = const Color(0xFF5F4B8B),
    this.displayText,
  }) : super(key: key);

  final int currentValue;
  final int maxValue;
  final double size;
  final Axis direction;
  final VerticalDirection verticalDirection;
  final double borderRadius;
  final Color backgroundColor;
  final Color progressColor;
  final int changeColorValue;
  final Color changeProgressColor;
  final String displayText;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final double position = currentValue / maxValue;

    final Widget progressWidget = Container(
      decoration: BoxDecoration(
        color: progressColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    // https://github.com/flutter/flutter/issues/14421
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: direction == Axis.vertical ? size : null,
          height: direction == Axis.horizontal ? size : null,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: borderWidth == 0
                ? null
                : Border.all(color: borderColor, width: borderWidth),
          ),
          child: Stack(
            children: <Widget>[
              Flex(
                direction: direction,
                verticalDirection: verticalDirection,
                children: <Widget>[
                  Expanded(
                    flex: (position * 100).toInt(),
                    child: progressWidget,
                  ),
                  Expanded(
                      flex: 100 - (position * 100).toInt(), child: Container())
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
