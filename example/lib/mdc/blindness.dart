import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluvsample/blocs/blocs.dart';

import '../dashboard_screen.dart';

class ColorBlindnessTheme extends StatelessWidget {
  const ColorBlindnessTheme({this.primaryColor, this.surfaceColor});

  final Color primaryColor;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final primaryBlind = retrieveColorBlindList(primaryColor);
    final surfaceBlind = retrieveColorBlindList(surfaceColor);

    return ListView(
      children: <Widget>[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
          child: Text(
            "Color Blindness",
            style: Theme.of(context).textTheme.title,
            textAlign: TextAlign.center,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
          child: Text(
            "Color blindness involves difficulty in perceiving or distinguishing between colors, as well as sensitivity to color brightness. It affects approximately one in twelve men and one in two hundred women worldwide.",
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Material(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.40),
                )),
            child: BlocBuilder<ColorBlindBloc, int>(
                builder: (BuildContext context, int state) {
              return Column(
                children: <Widget>[
                  for (int i = 0; i < primaryBlind.length; i++)
                    _RadioTile(
                      value: i,
                      groupValue: state,
                      backgroundColor: surfaceBlind[i].color,
                      primaryColor: primaryBlind[i].color,
                      onChanged: (int event) {
                        BlocProvider.of<ColorBlindBloc>(context).add(event);
                      },
                      title: primaryBlind[i].name,
                      subtitle: primaryBlind[i].affects,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    Key key,
    this.value,
    this.groupValue,
    this.title,
    this.subtitle,
    this.backgroundColor,
    this.primaryColor,
    this.onChanged,
  }) : super(key: key);

  final int value;
  final int groupValue;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color primaryColor;
  final Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      // According to https://github.com/flutter/flutter/issues/3782,
      // InkWell should be a child of Material, not Container.
      color: backgroundColor,
      child: InkWell(
        onTap: () => onChanged(value),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Theme(
                data: ThemeData(unselectedWidgetColor: primaryColor),
                child: Radio(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  activeColor: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .title
                        .copyWith(fontSize: 18),
                  ),
                  Text(subtitle, style: Theme.of(context).textTheme.caption),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
