import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../blocs/blocs.dart';
import '../util/color_util.dart';
import '../util/constants.dart';
import '../vertical_picker/vertical_picker_main.dart';
import '../widgets/update_color_dialog.dart';
import 'about.dart';
import 'color_library.dart';
import 'multiple_sliders.dart';
import 'single_color_blindness.dart';

class Home extends StatefulWidget {
  const Home({required this.initialColor});

  final Color initialColor;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ColorsCubit, ColorsState>(builder: (_, state) {
      final rgbColor = state.rgbColors[state.selected]!;
      final hsluvColor = state.hsluvColors[state.selected]!;

      final contrastedColor = (hsluvColor.lightness > kLightnessThreshold)
          ? Colors.black
          : Colors.white;

      final surfaceColor = blendColorWithBackground(rgbColor);

      final colorScheme = (rgbColor.computeLuminance() > kLumContrast)
          ? ColorScheme.light(
              primary: rgbColor,
              secondary: rgbColor,
              surface: surfaceColor,
            )
          : ColorScheme.dark(
              primary: rgbColor,
              secondary: rgbColor,
              surface: surfaceColor,
            );

      return Theme(
        data: ThemeData.from(
          // todo it would be nice if there were a ThemeData.join
          // because you need to copyWith manually everything every time.
          colorScheme: colorScheme,
        ).copyWith(
          cardTheme: Theme.of(context).cardTheme,
          buttonTheme: Theme.of(context).buttonTheme.copyWith(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
        ),
        child: Scaffold(
          backgroundColor: rgbColor,
          body: DefaultTabController(
            length: 5,
            initialIndex: 1,
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: TabBarView(
                      children: [
                        const MultipleSliders(),
                        HSVerticalPicker(
                          color: rgbColor,
                          hsLuvColor: hsluvColor,
                        ),
                        const SingleColorBlindness(),
                        const About(),
                        ColorLibrary(color: rgbColor),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          colorScheme.background.withOpacity(kVeryTransparent),
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.onSurface.withOpacity(0.40),
                        ),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        ThemeBar(),
                        TabBar(
                          labelColor: contrastedColor,
                          indicatorColor: contrastedColor,
                          isScrollable: true,
                          indicator: BoxDecoration(
                            color: colorScheme.onSurface.withOpacity(0.10),
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.onSurface,
                                width: 2.0,
                              ),
                            ),
                          ),
                          tabs: [
                            Tab(
                              icon: Transform.rotate(
                                angle: 0.5 * math.pi,
                                child: const Icon(FeatherIcons.sliders),
                              ),
                            ),
                            const Tab(icon: Icon(FeatherIcons.barChart2)),
                            Tab(icon: Icon(Icons.invert_colors)),
                            Tab(icon: Icon(FeatherIcons.info)),
                            Tab(icon: Icon(FeatherIcons.bookOpen)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

class ThemeBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: BlocBuilder<ColorsCubit, ColorsState>(builder: (_, state) {
        final list = state.rgbColors;

        return SizedBox(
          height: 36,
          child: ListView(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                const SizedBox(width: 16),
                for (int i = 0; i < list.length; i++) ...[
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: RawMaterialButton(
                      onPressed: () => context
                          .read<ColorsCubit>()
                          .updateRgbColor(rgbColor: list[i]!, selected: i),
                      onLongPress: () {
                        showSlidersDialog(context, list[i]!, i);
                      },
                      fillColor: list[i],
                      shape: CircleBorder(
                        side: BorderSide(
                          width: 2,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ),
                      ),
                      child: state.selected == i
                          ? Icon(
                              FeatherIcons.check,
                              size: 16,
                              color: contrastingColor(list[i]!),
                            )
                          : null,
                      elevation: 0.0,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const SizedBox(width: 8),
              ]),
        );
      }),
    );
  }
}
