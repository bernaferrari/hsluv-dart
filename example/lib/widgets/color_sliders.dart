import 'dart:math';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hsluv/flutter/hsluvcolor.dart';
import 'package:hsluvsample/widgets/slider_that_works.dart';

class RGBSlider extends StatefulWidget {
  const RGBSlider({Key key, this.color, this.onChanged}) : super(key: key);

  final Function(int, int, int) onChanged;
  final Color color;

  @override
  _RGBSliderState createState() => _RGBSliderState();
}

class _RGBSliderState extends State<RGBSlider> {
  int valueRed = 0;
  int valueBlue = 0;
  int valueGreen = 0;

  var colorRed = [Colors.black, const Color(0xFFFF0000)];
  var colorGreen = [Colors.black, const Color(0xFF00FF00)];
  var colorBlue = [Colors.black, const Color(0xFF0000FF)];

  String convertToHexString(int value) {
    return value.toRadixString(16).padLeft(2, '0');
  }

  void updateColorLists() {
    final vg = convertToHexString(valueGreen);
    final vr = convertToHexString(valueRed);
    final vb = convertToHexString(valueBlue);

    colorRed = [
      Color(int.parse("0xFF00$vg$vb")),
      Color(int.parse("0xFFFF$vg$vb"))
    ];
    colorGreen = [
      Color(int.parse("0xFF${vr}00$vb")),
      Color(int.parse("0xFF${vr}FF$vb"))
    ];
    colorBlue = [
      Color(int.parse("0xFF$vr${vg}00")),
      Color(int.parse("0xFF$vr${vg}FF"))
    ];
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    valueRed = color.red;
    valueGreen = color.green;
    valueBlue = color.blue;

    updateColorLists();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ColorSlider("Red", valueRed / 255, "$valueRed", colorRed,
            (double value) {
          setState(() {
            valueRed = (value * 255).round();
            updateColorLists();
            widget.onChanged(valueRed, valueGreen, valueBlue);
          });
        }),
        ColorSlider("Green", valueGreen / 255, "$valueGreen", colorGreen,
            (double value) {
          setState(() {
            valueGreen = (value * 255).round();
            updateColorLists();
            widget.onChanged(valueRed, valueGreen, valueBlue);
          });
        }),
        ColorSlider("Blue", valueBlue / 255, "$valueBlue", colorBlue,
            (double value) {
          setState(() {
            valueBlue = (value * 255).round();
            updateColorLists();
            widget.onChanged(valueRed, valueGreen, valueBlue);
          });
        }),
      ],
    );
  }
}

class HSVSlider extends StatefulWidget {
  const HSVSlider({Key key, this.color, this.onChanged}) : super(key: key);

  final Function(double, double, double) onChanged;
  final HSVColor color;

  @override
  _HSVSliderState createState() => _HSVSliderState();
}

class _HSVSliderState extends State<HSVSlider> {
  double valueH = 0.0;
  double valueS = 0.0;
  double valueB = 0.0;

  var colorH = [Colors.black, const Color(0xFFFF0000)];
  var colorS = [Colors.black, const Color(0xFFFF0000)];
  var colorB = [Colors.black, const Color(0xFFFF0000)];

  void updateColorLists() {
    final vh = valueH;
    final vs = valueS;
    final vb = valueB;

    colorH = [
      HSVColor.fromAHSV(1, 0, vs, vb).toColor(),
      HSVColor.fromAHSV(1, 60, vs, vb).toColor(),
      HSVColor.fromAHSV(1, 120, vs, vb).toColor(),
      HSVColor.fromAHSV(1, 180, vs, vb).toColor(),
      HSVColor.fromAHSV(1, 240, vs, vb).toColor(),
      HSVColor.fromAHSV(1, 300, vs, vb).toColor(),
      HSVColor.fromAHSV(1, 360, vs, vb).toColor(),
    ];
    colorS = [
      HSVColor.fromAHSV(1, vh, 0, vb).toColor(),
      HSVColor.fromAHSV(1, vh, 1.0, vb).toColor(),
    ];
    colorB = [
      HSVColor.fromAHSV(1, vh, vs, 0).toColor(),
      HSVColor.fromAHSV(1, vh, vs, 1).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hsv = widget.color;

    valueH = hsv.hue;
    valueS = hsv.saturation;
    valueB = hsv.value;
    updateColorLists();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ColorSlider("Hue", valueH / 360, "${valueH.round()}", colorH,
            (double value) {
          setState(() {
            valueH = value * 360;
            updateColorLists();
            widget.onChanged(valueH, valueS, valueB);
          });
        }),
        ColorSlider("Saturation", valueS, "${(valueS * 100).round()}", colorS,
            (double value) {
          setState(() {
            valueS = value;
            updateColorLists();
            widget.onChanged(valueH, valueS, valueB);
          });
        }),
        ColorSlider("Value", valueB, "${(valueB * 100).round()}", colorB,
            (double value) {
          setState(() {
            valueB = value;
            updateColorLists();
            widget.onChanged(valueH, valueS, valueB);
          });
        }),
      ],
    );
  }
}

class HSLSlider extends StatefulWidget {
  const HSLSlider({Key key, this.color, this.onChanged}) : super(key: key);

  final Function(double, double, double) onChanged;
  final HSLColor color;

  @override
  _HSLSliderState createState() => _HSLSliderState();
}

class _HSLSliderState extends State<HSLSlider> {
  double valueH = 0.0;
  double valueS = 0.0;
  double valueL = 0.0;

  var colorH = [Colors.black, const Color(0xFFFF0000)];
  var colorS = [Colors.black, const Color(0xFFFF0000)];
  var colorL = [Colors.black, const Color(0xFFFF0000)];

  void updateColorLists() {
    final vh = valueH;
    final vs = valueS;
    final vl = valueL;

    colorH = [
      HSLColor.fromAHSL(1, 0, vs, vl).toColor(),
      HSLColor.fromAHSL(1, 60, vs, vl).toColor(),
      HSLColor.fromAHSL(1, 120, vs, vl).toColor(),
      HSLColor.fromAHSL(1, 180, vs, vl).toColor(),
      HSLColor.fromAHSL(1, 240, vs, vl).toColor(),
      HSLColor.fromAHSL(1, 300, vs, vl).toColor(),
      HSLColor.fromAHSL(1, 360, vs, vl).toColor(),
    ];
    colorS = [
      HSLColor.fromAHSL(1, vh, 0, vl).toColor(),
      HSLColor.fromAHSL(1, vh, 1.0, vl).toColor(),
    ];
    colorL = [
      HSLColor.fromAHSL(1, vh, vs, 0).toColor(),
      HSLColor.fromAHSL(1, vh, vs, 0.5).toColor(),
      HSLColor.fromAHSL(1, vh, vs, 1).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hsl = widget.color;

    valueH = hsl.hue;
    valueS = hsl.saturation;
    valueL = hsl.lightness;

    updateColorLists();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ColorSlider("Hue", valueH / 360, "${valueH.round()}", colorH,
            (double value) {
          setState(() {
            valueH = value * 360;
            updateColorLists();
            widget.onChanged(valueH, valueS, valueL);
          });
        }),
        ColorSlider("Saturation", valueS, "${(valueS * 100).round()}", colorS,
            (double value) {
          setState(() {
            valueS = value;
            updateColorLists();
            widget.onChanged(valueH, valueS, valueL);
          });
        }),
        ColorSlider("Lightness", valueL, "${(valueL * 100).round()}", colorL,
            (double value) {
          setState(() {
            valueL = value;
            updateColorLists();
            widget.onChanged(valueH, valueS, valueL);
          });
        }),
      ],
    );
  }
}

class HSLuvSlider extends StatefulWidget {
  const HSLuvSlider({Key key, this.color, this.onChanged}) : super(key: key);

  final Function(double, double, double) onChanged;
  final HSLuvColor color;

  @override
  _HSLuvSliderState createState() => _HSLuvSliderState();
}

class _HSLuvSliderState extends State<HSLuvSlider> {
  double valueH = 0.0;
  double valueS = 0.0;
  double valueL = 0.0;

  var colorH = [Colors.black, const Color(0xFFFF0000)];
  var colorS = [Colors.black, const Color(0xFFFF0000)];
  var colorL = [Colors.black, const Color(0xFFFF0000)];

  void updateColorLists() {
    final vh = valueH;
    final vs = valueS;
    final vl = valueL;

    colorH = [
      HSLuvColor.fromHSL(0, vs, vl).toColor(),
      HSLuvColor.fromHSL(60, vs, vl).toColor(),
      HSLuvColor.fromHSL(120, vs, vl).toColor(),
      HSLuvColor.fromHSL(180, vs, vl).toColor(),
      HSLuvColor.fromHSL(240, vs, vl).toColor(),
      HSLuvColor.fromHSL(300, vs, vl).toColor(),
      HSLuvColor.fromHSL(360, vs, vl).toColor(),
    ];
    colorS = [
      HSLuvColor.fromHSL(vh, 0.0, vl).toColor(),
      HSLuvColor.fromHSL(vh, 100.0, vl).toColor(),
    ];
    colorL = [
      HSLuvColor.fromHSL(vh, vs, 0).toColor(),
      HSLuvColor.fromHSL(vh, vs, 50).toColor(),
      HSLuvColor.fromHSL(vh, vs, 100).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hsl = widget.color;

    valueH = hsl.hue;
    valueS = hsl.saturation;
    valueL = hsl.lightness;
    updateColorLists();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // when max value is 360, it occasionally jumps to 0 because of
        // its own nature. Keeping <= 359 should be unnoticeable.
        // The math.min will avoid 360 / 359 situations where value will be >= 1.0.
        ColorSlider(
            "Hue", math.min(valueH / 359, 1.0), "${valueH.round()}", colorH,
            (double value) {
          setState(() {
            valueH = value * 359;
            updateColorLists();
            widget.onChanged(valueH, valueS, valueL);
          });
        }),
        ColorSlider("Saturation", valueS / 100, "${valueS.round()}", colorS,
            (double value) {
          setState(() {
            valueS = value * 100;
            updateColorLists();
            widget.onChanged(valueH, valueS, valueL);
          });
        }),
        ColorSlider("Lightness", valueL / 100, "${valueL.round()}", colorL,
            (double value) {
          setState(() {
            valueL = value * 100;
            updateColorLists();
            widget.onChanged(valueH, valueS, valueL);
          });
        }),
      ],
    );
  }
}

class GradientRoundedRectSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  /// Create a slider track that draws two rectangles with rounded outer edges.
  const GradientRoundedRectSliderTrackShape(this.colors);

  final List<Color> colors;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    @required RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    @required Animation<double> enableAnimation,
    @required TextDirection textDirection,
    @required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    assert(context != null);
    assert(offset != null);
    assert(parentBox != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledActiveTrackColor != null);
    assert(sliderTheme.disabledInactiveTrackColor != null);
    assert(sliderTheme.activeTrackColor != null);
    assert(sliderTheme.inactiveTrackColor != null);
    assert(sliderTheme.thumbShape != null);
    assert(enableAnimation != null);
    assert(textDirection != null);
    assert(thumbCenter != null);
    // If the slider track height is less than or equal to 0, then it makes no
    // difference whether the track is painted or not, therefore the painting
    // can be a no-op.
    if (sliderTheme.trackHeight <= 0) {
      return;
    }

    // Assign the track segment paints, which are leading: active and
    // trailing: inactive.
    final gradient = LinearGradient(
      tileMode: TileMode.clamp,
      colors: colors,
    );

    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint activePaint = Paint()
      ..shader = gradient.createShader(trackRect);

    final Paint leftTrackPaint = activePaint;
    final Paint rightTrackPaint = activePaint;

    // The arc rects create a semi-circle with radius equal to track height.
    // The 0.3 is necessary for unknown reasons, else there is a small line that shows up.
    final Rect leftTrackArcRect = Rect.fromLTWH(
        trackRect.left - trackRect.height / 2 + 0.3,
        trackRect.top,
        trackRect.height,
        trackRect.height);
    if (!leftTrackArcRect.isEmpty)
      context.canvas
          .drawArc(leftTrackArcRect, pi / 2, pi, false, leftTrackPaint);
    final Rect rightTrackArcRect = Rect.fromLTWH(
        trackRect.right - trackRect.height / 2 - 0.3,
        trackRect.top,
        trackRect.height,
        trackRect.height);
    if (!rightTrackArcRect.isEmpty)
      context.canvas
          .drawArc(rightTrackArcRect, -pi / 2, pi, false, rightTrackPaint);

    final Rect fullTrackArc = Rect.fromLTRB(
        trackRect.left, trackRect.top, trackRect.right, trackRect.bottom);
    if (!fullTrackArc.isEmpty)
      context.canvas.drawRect(fullTrackArc, rightTrackPaint);
  }
}

class ColorSlider extends StatelessWidget {
  const ColorSlider(
      this.title, this.value, this.strValue, this.colorList, this.onChanged);

  final String title;
  final double value;
  final String strValue;
  final List<Color> colorList;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 40,
        thumbColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        trackShape: GradientRoundedRectSliderTrackShape(colorList),
        thumbShape: RoundSliderThumbShape2(strValue: strValue),
      ),
      child: Slider2(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class RoundSliderThumbShape2 extends SliderComponentShape {
  /// Create a slider thumb that draws a circle.
  const RoundSliderThumbShape2({
    this.enabledThumbRadius = 20.0,
    this.disabledThumbRadius,
    this.strValue,
  });

  final String strValue;

  /// The preferred radius of the round thumb shape when the slider is enabled.
  ///
  /// If it is not provided, then the material default of 10 is used.
  final double enabledThumbRadius;

  /// The preferred radius of the round thumb shape when the slider is disabled.
  ///
  /// If no disabledRadius is provided, then it is equal to the
  /// [enabledThumbRadius]
  final double disabledThumbRadius;

  double get _disabledThumbRadius => disabledThumbRadius ?? enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(
        isEnabled == true ? enabledThumbRadius : _disabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    Animation<double> activationAnimation,
    @required Animation<double> enableAnimation,
    bool isDiscrete,
    TextPainter labelPainter,
    RenderBox parentBox,
    @required SliderThemeData sliderTheme,
    TextDirection textDirection,
    double value,
  }) {
    assert(context != null);
    assert(center != null);
    assert(enableAnimation != null);
    assert(sliderTheme != null);
    assert(sliderTheme.disabledThumbColor != null);
    assert(sliderTheme.thumbColor != null);

    final Canvas canvas = context.canvas;
    final Tween<double> radiusTween = Tween<double>(
      begin: _disabledThumbRadius,
      end: enabledThumbRadius,
    );
    final ColorTween colorTween = ColorTween(
      begin: sliderTheme.disabledThumbColor,
      end: sliderTheme.thumbColor,
    );
    canvas.drawCircle(
      center,
      radiusTween.evaluate(enableAnimation),
      Paint()..color = colorTween.evaluate(enableAnimation),
    );

    final textStyle =
        TextStyle(color: Colors.black, fontSize: 14, fontFamily: "B612Mono");
    final textSpan = TextSpan(
      text: strValue,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: 256,
    );

    center.translate(textPainter.width / 2, textPainter.height / 2);

    textPainter.paint(canvas,
        center.translate(-textPainter.width / 2, -textPainter.height / 2));
  }
}
