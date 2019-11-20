import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluvsample/blocs/blocs.dart';
import 'package:hsluvsample/blocs/mdc_selected/mdc_selected_event.dart';
import 'package:hsluvsample/util/color_util.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:hsluvsample/util/selected.dart';

import 'components.dart';

class ColorTemplates extends StatelessWidget {
  const ColorTemplates(
      {this.primaryColor, this.surfaceColor, this.backgroundColor});

  final Color primaryColor;
  final Color surfaceColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: surfaceColor,
      child: ListView(
        key: const PageStorageKey("Templates"),
        children: <Widget>[
          const SizedBox(height: 16),
          Text(
            "Dark Templates",
            style: Theme.of(context).textTheme.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Get inspired by others.",
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const _TemplateItem(
              title: "Twitter", colors: [Color(0xff1da1f3), Color(0xff16202a)]),
          const _TemplateItem(
              title: "Clock", colors: [Color(0xff89b4f8), Color(0xff202125)]),
          const _TemplateItem(
              title: "Flamingo",
              colors: [Color(0xff4286f5), Color(0xff1b1b1b)]),
          // from Sam Houston
          const _TemplateItem(
              title: "Twilight",
              colors: [Color(0xff319de6), Color(0xff20222f)]),
          // Facebook's Threads app
          const _TemplateItem(
              title: "Midnight",
              colors: [Color(0xfff2355b), Color(0xff000000)]),
          // Facebook's Threads app
          const _TemplateItem(
              title: "Aurora", colors: [Color(0xff2a9a8c), Color(0xff001b12)]),
          // Facebook's Threads app
          const _TemplateItem(
              title: "Play Store",
              colors: [Color(0xff00a273), Color(0xff202125)]),
          // Google Play Store
          const _TemplateItem(
              title: "Play Games",
              colors: [Color(0xff5bda7f), Color(0xff202125)]),
          // Google Play Store
          const _TemplateItem(
              title: "Play Movies",
              colors: [Color(0xffcc2948), Color(0xff202125)]),
          // Google Play Store
          const _TemplateItem(
              title: "PocketCasts",
              colors: [Color(0xff33b8f3), Color(0xff161719)]),
          // PocketCasts
          const _TemplateItem(
              title: "PocketCasts",
              colors: [Color(0xffeb4745), Color(0xff1a1b1d)]),
          // I was listening to Wendover podcast and liked the colors in PocketCasts
          const _TemplateItem(
              title: "Champagne",
              colors: [Color(0xffff596a), Color(0xff081110)]),
          // I was listening to Andrea Bocelli's Champagne and liked the color from Spotify cover on Android notification
          const _TemplateItem(
              title: "Nu", colors: [Color(0xffBA4DE4), Color(0xff191919)]),
          const _TemplateItem(
              title: "Bixby", colors: [Color(0xff3c8eb3), Color(0xff090b20)]),
          const _TemplateItem(
              title: "Action", colors: [Color(0xff4286f3), Color(0xff33333d)]),
          const _TemplateItem(
              title: "Rally", colors: [Color(0xffffcf44), Color(0xff32333D)]),
          const _TemplateItem(
              title: "Crane", colors: [Color(0xffffffff), Color(0xff5c0f48)]),
          const _TemplateItem(
              title: "B&W", colors: [Color(0xffffffff), Color(0xff000000)]),
          const SizedBox(height: 16),
          Text(
            "Light Templates",
            style: Theme.of(context).textTheme.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "App also works fine.",
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const _TemplateItem(
              title: "W&B", colors: [Color(0xff000000), Color(0xffffffff)]),
          const _TemplateItem(
              title: "Hurry", colors: [Color(0xff101010), Color(0xfff0eff5)]),
          const _TemplateItem(
              title: "Mingo", colors: [Color(0xff3e3e3e), Color(0xfff0f0f0)]),
          const _TemplateItem(
              title: "Basil", colors: [Color(0xff356859), Color(0xfffffbe6)]),
          const _TemplateItem(
              title: "Shrine", colors: [Color(0xff442c2e), Color(0xfffedbd0)]),
          const _TemplateItem(
              title: "Reply 1", colors: [Color(0xff496572), Color(0xffedf0f2)]),
          const _TemplateItem(
              title: "Reply 2", colors: [Color(0xfff9aa33), Color(0xfffefefe)]),
          const _TemplateItem(
              title: "Crane", colors: [Color(0xffE31E24), Color(0xffF8F8F8)]),
          const _TemplateItem(
              title: "Fortnightly",
              colors: [Color(0xff6b38fb), Color(0xffffffff)]),
          const _TemplateItem(
              title: "Owl 1", colors: [Color(0xffffde03), Color(0xff0336ff)]),
          const _TemplateItem(
              title: "Owl 2", colors: [Color(0xff000000), Color(0xffff0266)]),
          const _TemplateItem(
              title: "SamClock",
              colors: [Color(0xff6063F0), Color(0xfffcfcfc)]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TemplateItem extends StatelessWidget {
  const _TemplateItem({this.title, this.colors});

  final String title;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 16),
          Expanded(
            child: RaisedButton(
              color: colors[1],
              elevation: 0,
              textColor: colors[0],
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.subtitle.copyWith(
                        color: colors[0]
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right),
                  const SizedBox(width: 8),
                ],
              ),
              onPressed: () {
                BlocProvider.of<MdcSelectedBloc>(context).add(MDCUpdateAllEvent(
                  primaryColor: colors[0],
                  surfaceColor: colors[1],
                  selectedTitle: kPrimary,
                ));
                colorSelected(context, colors[0]);
              },
            ),
          ),
          const SizedBox(width: 16),
          for (var color in colors) ...[
            FilterChip(
                label: SizedBox(
                    width: 60,
                    child: Text(
                      color.toHexStr(),
                      style: Theme.of(context)
                          .textTheme
                          .body2
                          .copyWith(color: contrastingColor(color)),
                      textAlign: TextAlign.center,
                    )),
                backgroundColor: color,
                onSelected: (selected) {
                  colorSelected(context, color);
                }),
            const SizedBox(width: 16)
          ],
        ],
      ),
    );
  }
}
