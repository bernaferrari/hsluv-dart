import 'package:flutter/material.dart';

class SliderWithSelector extends StatefulWidget {
  const SliderWithSelector(this.rgb, this.hsv, this.hsl, this.context);

  final Widget rgb;
  final Widget hsv;
  final Widget hsl;

  // this is necessary to save the selected position.
  // Flutter will discard the Dialog's context when Dialog closes.
  final BuildContext context;

  @override
  _SliderWithSelectorState createState() => _SliderWithSelectorState();
}

class _SliderWithSelectorState extends State<SliderWithSelector> {
  List<bool> isSelected;

  @override
  void initState() {
    isSelected = PageStorage.of(widget.context).readState(widget.context,
            identifier: const ValueKey("Selectable Sliders")) ??
        [true, false, false];

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ToggleButtons(
          textStyle: const TextStyle(fontFamily: "B612Mono"),
          children: const <Widget>[
            Text("RGB"),
            Text("HSV"),
            Text("HSLuv"),
          ],
          onPressed: (int index) {
            setState(() {
              for (int buttonIndex = 0;
                  buttonIndex < isSelected.length;
                  buttonIndex++) {
                if (buttonIndex == index) {
                  isSelected[buttonIndex] = true;
                } else {
                  isSelected[buttonIndex] = false;
                }
              }
              PageStorage.of(widget.context).writeState(
                  widget.context, isSelected,
                  identifier: const ValueKey("Selectable Sliders"));
            });
          },
          isSelected: isSelected,
        ),
        Padding(
          // this is the right padding, so text don't get glued to the border.
          padding: const EdgeInsets.only(top: 16),
          child: isSelected[0]
              ? widget.rgb
              : isSelected[1] ? widget.hsl : widget.hsv,
        ),
      ],
    );
  }
}
