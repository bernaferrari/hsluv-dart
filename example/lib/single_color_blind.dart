import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluvsample/util/color_blindness.dart';
import 'package:hsluvsample/util/selected.dart';
import 'package:hsluvsample/vertical_picker/app_bar.dart';
import 'package:hsluvsample/widgets/loading_indicator.dart';

import 'blocs/slider_color/slider_color_bloc.dart';
import 'blocs/slider_color/slider_color_state.dart';
import 'dashboard_screen.dart';
import 'mdc/components.dart';
import 'util/color_util.dart';

class BlindScreen extends StatelessWidget {
  const BlindScreen();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SliderColorBloc, SliderColorState>(
      builder: (context, state) {
        if (state is SliderColorLoading) {
          return const Scaffold(body: Center(child: LoadingIndicator()));
        }

        final color = (state as SliderColorLoaded).rgbColor;
        final surfaceColor = blendColorWithBackground(color);
        final values = retrieveColorBlind(color);

        return Theme(
          data: ThemeData.from(
            colorScheme: ColorScheme.dark(surface: surfaceColor),
          ).copyWith(
            cardTheme: Theme.of(context).cardTheme,
            buttonTheme: Theme.of(context).buttonTheme,
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Color Blindness"),
              actions: <Widget>[
                ColorSearchButton(color: color),
                const SizedBox(width: 8),
              ],
            ),
            backgroundColor: color,
            body: Card(
              margin: const EdgeInsets.all(16),
              child: ListView(
                key: const PageStorageKey("color_blind"),
                children: <Widget>[
                  const SizedBox(height: 16),
                  for (var key in values.keys) ...[
                    Text(
                      key,
                      style: Theme.of(context).textTheme.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: LayoutBuilder(
                        builder: (context, builder) {
                          final numOfItems = (builder.maxWidth / 280).floor();
                          return Wrap(
                            children: <Widget>[
                              for (var value in values[key]) ...[
                                SizedBox(
                                  width: builder.maxWidth / numOfItems,
                                  height: 80,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: _ColorBlindCard(value, color),
                                  ),
                                )
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (key != "Monochromacy") const Divider(),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // sources:
  // https://www.color-blindness.com/
  // https://www.color-blindness.com/category/tools/
  // https://en.wikipedia.org/wiki/Color_blindness
  // https://en.wikipedia.org/wiki/Dichromacy
  Map<String, List<ColorWithBlind>> retrieveColorBlind(Color color) {
    const m = "of males";
    const f = "of females";
    const p = "of population";

    return {
      "Trichromacy": [
        ColorWithBlind(protanomaly(color), "Protanomaly", "1% $m, 0.01% $f"),
        ColorWithBlind(deuteranomaly(color), "Deuteranomaly", "6% $m, 0.4% $f"),
        ColorWithBlind(tritanomaly(color), "Tritanomaly", "0.01% $p"),
      ],
      "Dichromacy": [
        ColorWithBlind(protanopia(color), "Protanopia", "1% $m"),
        ColorWithBlind(deuteranopia(color), "Deuteranopia", "1% $m"),
        ColorWithBlind(tritanopia(color), "Tritanopia", "less than 1% $p"),
      ],
      "Monochromacy": [
        ColorWithBlind(achromatopsia(color), "Achromatopsia", "0.003% $p"),
        ColorWithBlind(achromatomaly(color), "Achromatomaly", "0.001% $p"),
      ],
    };
  }
}

class _ColorBlindCard extends StatelessWidget {
  const _ColorBlindCard(this.blindColor, this.defaultColor);

  final Color defaultColor;
  final ColorWithBlind blindColor;

  @override
  Widget build(BuildContext context) {
    final contrastedColor = contrastingColor(blindColor.color);

    return MaterialButton(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: blindColor.color,
      elevation: 0,
      onPressed: () {
        colorSelected(context, blindColor.color);
      },
      child: Row(
        children: <Widget>[
          const SizedBox(width: 8),
          Text(
            blindColor.name[0],
            style: Theme.of(context).textTheme.headline.copyWith(
                  fontWeight: FontWeight.w700,
                  color: defaultColor,
                  fontSize: 48,
                ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  blindColor.name,
                  style: Theme.of(context).textTheme.title.copyWith(
                        fontSize: 18,
                        color: contrastedColor,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "${blindColor.color.toHexStr()}  •  ${blindColor.affects}",
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .caption
                      .copyWith(color: contrastedColor.withOpacity(0.87)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}