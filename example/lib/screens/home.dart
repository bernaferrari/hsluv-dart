import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hsluvsample/mdc/components.dart';
import 'package:hsluvsample/screens/about.dart';
import 'package:hsluvsample/screens/multiple_sliders.dart';
import 'package:hsluvsample/screens/single_color_blindness.dart';
import 'package:hsluvsample/util/color_util.dart';
import 'package:hsluvsample/util/selected.dart';
import 'package:hsluvsample/util/when.dart';
import 'package:hsluvsample/vertical_picker/vertical_picker_main.dart';
import 'package:hsluvsample/widgets/loading_indicator.dart';
import 'package:hsluvsample/widgets/update_color_dialog.dart';

import '../blocs/blocs.dart';
import '../util/constants.dart';

class Home extends StatefulWidget {
  const Home({this.initialColor});

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
    return BlocBuilder<MultipleContrastColorBloc, MultipleContrastColorState>(
        builder: (context, state) {
      if (state is MultipleContrastColorLoading) {
        return Scaffold(
          backgroundColor: widget.initialColor,
          body: const LoadingIndicator(),
        );
      }

      final currentState = state as MultipleContrastColorLoaded;

      final color = currentState.colorsList[currentState.selected].rgbColor;

      final contrastedColor = (color.computeLuminance() > kLumContrast)
          ? Colors.black
          : Colors.white;

      final surfaceColor = blendColorWithBackground(color);

      final colorScheme = (color.computeLuminance() > kLumContrast)
          ? ColorScheme.light(
              primary: color,
              secondary: color,
              surface: surfaceColor,
            )
          : ColorScheme.dark(
              primary: color,
              secondary: color,
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
          backgroundColor: color,
          body: DefaultTabController(
            length: 4,
            initialIndex: 1,
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: TabBarView(
                      children: [
                        const MultipleSliders(),
                        HSVerticalPicker(color: color),
                        const SingleColorBlindness(),
                        const About(),
                      ],
                    ),
                  ),
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
                    ],
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
  final bool themeMode = false;

  @override
  Widget build(BuildContext context) {
    final accentColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.40);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .background
          .withOpacity(kVeryTransparent),
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: themeMode
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 36,
                    child: FlatButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/theme');
                      },
                      icon: Icon(FeatherIcons.layout,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurface),
                      label: Text(
                        "Theming",
                        style: Theme.of(context).textTheme.body2.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 24,
                    color: accentColor,
                  ),
                  const SizedBox(width: 16),
                  const RoundSelectableColor(kPrimary),
                  const SizedBox(width: 8),
                  const RoundSelectableColor(kSurface),
                  const SizedBox(width: 8),
                ],
              )
            : BlocBuilder<MultipleContrastColorBloc,
                MultipleContrastColorState>(builder: (context, state) {
                if (state is MultipleContrastColorLoading) {
                  return const Center(child: LoadingIndicator());
                }

                final selected =
                    (state as MultipleContrastColorLoaded).selected;

                final list = (state as MultipleContrastColorLoaded).colorsList;
                return SizedBox(
                  height: 36,
                  child: ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      children: <Widget>[
                        const SizedBox(width: 16),
                        for (int i = 0; i < list.length; i++) ...[
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: RawMaterialButton(
                              onPressed: () {
                                BlocProvider.of<MultipleContrastColorBloc>(
                                        context)
                                    .add(
                                  MCMoveColor(list[i].rgbColor, i),
                                );
                              },
                              onLongPress: () {
                                showSlidersDialog(context, list[i].rgbColor, i);
                              },
                              fillColor: list[i].rgbColor,
                              shape: CircleBorder(
                                side: BorderSide(
                                  width: 2,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                              child: selected == i
                                  ? Icon(
                                      FeatherIcons.check,
                                      size: 16,
                                      color: contrastingColor(list[i].rgbColor),
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
      ),
    );
  }
}

class RoundSelectableColor extends StatelessWidget {
  const RoundSelectableColor(this.kind);

  final String kind;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MdcSelectedBloc, MdcSelectedState>(
        builder: (context, state) {
      final selected = (state as MDCLoadedState).selected;
      final allItems = (state as MDCLoadedState).blindness;

      final Color primaryColor = allItems[kPrimary];
      final Color surfaceColor = allItems[kSurface];

      final Color correctColor = when({
        () => kind == kPrimary: () => primaryColor,
        () => kind == kSurface: () => surfaceColor,
      });

      return SizedBox(
        width: 24,
        height: 24,
        child: RawMaterialButton(
          onPressed: () {
            BlocProvider.of<MdcSelectedBloc>(context).add(
              MDCUpdateAllEvent(
                primaryColor: primaryColor,
                surfaceColor: surfaceColor,
                selectedTitle: kind,
              ),
            );
            colorSelected(context, correctColor);
          },
          fillColor: correctColor,
          shape: CircleBorder(
            side: BorderSide(
              width: 2,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          child: kind == selected ? Icon(FeatherIcons.check, size: 16) : null,
          elevation: 0.0,
          padding: EdgeInsets.zero,
        ),
      );
    });
  }
}
