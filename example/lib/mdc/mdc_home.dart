import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hsluvsample/blocs/blocs.dart';
import 'package:hsluvsample/contrast/color_with_contrast.dart';
import 'package:hsluvsample/mdc/settings.dart';
import 'package:hsluvsample/mdc/showcase.dart';
import 'package:hsluvsample/mdc/templates.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:hsluvsample/util/selected.dart';

import 'components.dart';
import 'contrast_compare.dart';

class MDCHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MdcSelectedBloc, MdcSelectedState>(
        builder: (context, state) {
      final selected = (state as MDCLoadedState).selected;
      final allItems = (state as MDCLoadedState).allItems;

      final Color primaryColor = allItems[kPrimary];
      final Color surfaceColor = allItems[kSurface];
      final Color backgroundColor =
          surfaceColor; //allItems["Background"].color;

      final contrast = calculateContrast(primaryColor, surfaceColor);

      final base = Theme.of(context);

      final scheme = surfaceColor.computeLuminance() > kLumContrast
          ? ColorScheme.light(
              surface: surfaceColor,
              primary: primaryColor,
              secondary: primaryColor,
            )
          : ColorScheme.dark(
              surface: surfaceColor,
              primary: primaryColor,
              secondary: primaryColor,
            );

      return Theme(
        data: ThemeData.from(colorScheme: scheme).copyWith(
//          colorScheme: base.colorScheme
//              .copyWith(surface: surfaceColor, primary: primaryColor),
          cardColor: surfaceColor,
          cardTheme: base.cardTheme,
          toggleableActiveColor: primaryColor,
          toggleButtonsTheme: ToggleButtonsThemeData(color: scheme.onSurface),
          buttonTheme: base.buttonTheme.copyWith(
            // this is needed for the outline color
            colorScheme: scheme,
          ),
        ),
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(),
            body: DefaultTabController(
              length: 5,
              initialIndex: 1,
              child: Column(
                children: <Widget>[
                  TabBar(
                    isScrollable: true,
                    tabs: [
                      const Tab(icon: const Text("MDC")),
                      Tab(icon: Icon(FeatherIcons.list)),
                      Tab(icon: Icon(contrast > 4 ? FeatherIcons.smile : FeatherIcons.frown)),
                      Tab(icon: Icon(FeatherIcons.briefcase)),
                      Tab(icon: Icon(FeatherIcons.settings)),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Components(
                          primaryColor: primaryColor,
                          surfaceColor: surfaceColor,
                          backgroundColor: backgroundColor,
                        ),
                        Showcase(
                          primaryColor: primaryColor,
                          surfaceColor: surfaceColor,
                          backgroundColor: backgroundColor,
                        ),
                        ContrastComparison(
                          primaryColor: primaryColor,
                          surfaceColor: surfaceColor,
                          backgroundColor: backgroundColor,
                        ),
                        ColorTemplates(
                          primaryColor: primaryColor,
                          surfaceColor: surfaceColor,
                          backgroundColor: backgroundColor,
                        ),
                        Settings(),
                      ],
                    ),
                  ),
                  Container(
                    height: 56,
                    child: Center(
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        children: <Widget>[
                          IconButton(
                            tooltip: "Shuffle Colors",
                            icon: Icon(FeatherIcons.shuffle, size: 20,),
                            onPressed: () {

                            },
                          ),
                          for (var key in allItems.keys)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CheckedButton(
                                title: key,
                                color: allItems[key],
                                isSelected: key == selected,
                                onPressed: () {
                                  colorSelected(context, allItems[key]);
                                  BlocProvider.of<MdcSelectedBloc>(context)
                                      .add(MDCLoadEvent(
                                    currentColor: allItems[selected],
                                    currentTitle: selected,
                                    selectedTitle: key,
                                  ));
                                },
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SizedBox(
                              width: 48,
                              child: FlatButton(
                                child: Text("Edit"),
                                onPressed: () {

                                },
                              ),
                            ),
                          )
                        ],
                      ),
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
}

class _SelectableMenu extends StatefulWidget {
  const _SelectableMenu({this.children});

  final List<Widget> children;

  @override
  __SelectableMenuState createState() => __SelectableMenuState();
}

class __SelectableMenuState extends State<_SelectableMenu> {
  List<bool> isSelected = [true, false, false, false];

  @override
  void initState() {
    final List<bool> wasSelected = PageStorage.of(context)
        .readState(context, identifier: const ValueKey("MDC Selected"));
    if (wasSelected != null) {
      isSelected = wasSelected;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ToggleButtons(
          textStyle: const TextStyle(fontFamily: "B612Mono"),
          children: <Widget>[
            const Text("MDC"),
            // material design components, in the absence of a decent icon.
            Icon(FeatherIcons.list),
            // list of different UIs.
            Icon(FeatherIcons.smile),
            // a good contrast might not make people smile, but a bad contrast will certainly make them cry.
            Icon(FeatherIcons.briefcase),
            // get inspired by someone who already did the job for you
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
              PageStorage.of(context).writeState(context, isSelected,
                  identifier: const ValueKey("MDC Selected"));
            });
          },
          isSelected: isSelected,
        ),
        Expanded(
          child: widget.children[isSelected.indexOf(true)],
        ),
      ],
    );
  }
}
