import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:material/multiple_sliders.dart';
import 'package:material/screen_about.dart';
import 'package:material/util/color_util.dart';
import 'package:material/util/selected.dart';
import 'package:material/widgets/color_sliders.dart';
import 'package:material/widgets/loading_indicator.dart';

import 'blocs/slider_color/slider_color.dart';
import 'hsluv_selector.dart';
import 'hsv_selector.dart';
import 'util/constants.dart';

class ColorHome extends StatefulWidget {
  const ColorHome({this.initialColor});

  final Color initialColor;

  @override
  _ColorHomeState createState() => _ColorHomeState();
}

class _ColorHomeState extends State<ColorHome> {
  TextEditingController _textEditingController;
  SliderColorBloc _bloc;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _bloc = BlocProvider.of<SliderColorBloc>(context);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SliderColorBloc, SliderColorState>(
        builder: (context, state) {
      if (state is SliderColorLoading) {
        return Scaffold(
          backgroundColor: widget.initialColor,
          body: const LoadingIndicator(),
        );
      }

      final color = (state as SliderColorLoaded).rgbColor;

      if ((state as SliderColorLoaded).updateTextField) {
        final clrStr = colorToStr(color);
        // without this, the cursor will be on the first position, not on last,
        // when keyboard is opened.
        if (_textEditingController.text != clrStr) {
          _textEditingController.text = clrStr;
        }
      }

      final rgb = RGBSlider(
          color: (state as SliderColorLoaded).rgbColor,
          onChanged: (r, g, b) {
            BlocProvider.of<SliderColorBloc>(context).add(MoveRGB(r, g, b));
          });

      final hsl = HSLSlider(
          color: (state as SliderColorLoaded).hslColor,
          onChanged: (h, s, l) {
            _bloc.add(MoveHSL(h, s, l));
          });

      final hsv = HSVSlider(
          color: (state as SliderColorLoaded).hsvColor,
          onChanged: (h, s, v) {
            _bloc.add(MoveHSV(h, s, v));
          });

      final contrastedColor = (color.computeLuminance() > kLumContrast)
          ? Colors.black
          : Colors.white;

      final surfaceColor = blendColorWithBackground(color);

      return Theme(
        data: ThemeData.from(
          // todo it would be nice if there were a ThemeData.join
          // because you need to copyWith manually everything every time.
          colorScheme: ColorScheme.dark(
            primary: color,
            secondary: color,
            surface: surfaceColor,
          ),
        ).copyWith(
          cardTheme: Theme.of(context).cardTheme,
          buttonTheme: Theme.of(context).buttonTheme.copyWith(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
        ),
        child: Scaffold(
          backgroundColor: color,
          appBar: AppBar(
            iconTheme: IconThemeData(color: contrastedColor),
            actions: <Widget>[
              _CopyColorButton(color: color),
            ],
            title: TextFormField(
              controller: _textEditingController,
              onChanged: (str) {
                _bloc.add(MoveColor(
                    Color(int.parse("0xFF${str.padRight(6, "F")}")), false));
              },
              inputFormatters: [
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white38, width: 2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black26, width: 2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
                filled: true,
                fillColor: (color.computeLuminance() > kLumContrast)
                    ? Colors.black12
                    : Colors.white24,
                isDense: true,
                prefix: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(FeatherIcons.hash, size: 16),
                ),
              ),
              style: Theme.of(context)
                  .textTheme
                  .title
                  .copyWith(color: contrastedColor),
            ),
            backgroundColor: color,
            elevation: 0,
            centerTitle: false,
          ),
          body: DefaultTabController(
            length: 4,
            initialIndex: 1,
            child: Column(
              children: <Widget>[
                TabBar(
                  labelColor: contrastedColor,
                  indicatorColor: contrastedColor,
                  isScrollable: true,
                  tabs: [
                    Tab(
                      icon: Transform.rotate(
                          angle: 0.5 * Math.pi,
                          child: Icon(FeatherIcons.sliders)),
                    ),
                    const Tab(icon: Text("HSLuv")),
                    const Tab(icon: Text("HSV")),
                    Tab(icon: Icon(FeatherIcons.info)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ColorSliders(rgb, hsv, hsl),
                      HSLuvSelector(color: widget.initialColor),
                      BetterColorSelector(color: widget.initialColor),
                      AboutScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget cardPicker(String title, Widget picker) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: picker,
          ),
        ],
      ),
    );
  }
}

class _CopyColorButton extends StatelessWidget {
  // this needs to be in a separate widget to avoid this error:
  // https://stackoverflow.com/questions/51304568/scaffold-of-called-with-a-context-that-does-not-contain-a-scaffold
  const _CopyColorButton({Key key, this.color}) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.only(left: 8, right: 16),
      tooltip: "copy color",
      icon: Icon(FeatherIcons.copy),
      onPressed: () {
        copyToClipboard(context, colorToStr(color));
      },
    );
  }
}
