import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SliderWithSelector extends StatefulWidget {
  const SliderWithSelector(this.sliders, this.color, this.context);

  final Color color;
  final List<Widget> sliders;

  // this is necessary to save the selected position.
  // Flutter will discard the Dialog's context when Dialog closes.
  final BuildContext context;

  @override
  _SliderWithSelectorState createState() => _SliderWithSelectorState();
}

class _SliderWithSelectorState extends State<SliderWithSelector> {
  @override
  void initState() {
    currentSegment = PageStorage.of(widget.context).readState(widget.context,
            identifier: const ValueKey("Selectable Sliders")) ??
        0;

    super.initState();
  }

  final Map<int, Widget> children = const <int, Widget>{
    0: Text("RGB"),
    1: Text("HSLuv"),
    2: Text("HSV"),
  };

  int currentSegment = 0;

  void onValueChanged(int newValue) {
    setState(() {
      currentSegment = newValue;
      PageStorage.of(widget.context).writeState(widget.context, currentSegment,
          identifier: const ValueKey("Selectable Sliders"));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CupertinoSlidingSegmentedControl<int>(
          children: children,
          thumbColor: widget.color,
          onValueChanged: onValueChanged,
          groupValue: currentSegment,
        ),
        Padding(
          // this is the right padding, so text don't get glued to the border.
          padding: const EdgeInsets.only(top: 8),
          child: widget.sliders[currentSegment],
        ),
      ],
    );
  }
}
