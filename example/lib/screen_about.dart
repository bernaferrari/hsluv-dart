import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hsluvsample/contrast/contrast_screen.dart';
import 'package:hsluvsample/util/color_util.dart';
import 'package:hsluvsample/widgets/dismiss_keyboard_on_scroll.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.from(
        colorScheme: ColorScheme.dark(
          surface: blendColorWithBackground(color),
        ),
      ).copyWith(cardTheme: Theme.of(context).cardTheme),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 818),
          child: ListView(
            key: const PageStorageKey("about"),
            shrinkWrap: true,
            children: [
              const Padding(padding: EdgeInsets.all(4)),
              Card(
                margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: _ContactInfo(),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: ColorCompare(color: color),
              ),
              const Card(
                clipBehavior: Clip.antiAlias,
                margin: EdgeInsets.only(left: 16, right: 16, top: 16),
                child: MoreColors(),
              ),
              GDPR(),
              const Padding(padding: EdgeInsets.all(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreColors extends StatelessWidget {
  const MoreColors({this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return WatchBoxBuilder(
      box: Hive.box<dynamic>("settings"),
      builder: (context, box) {
        return SwitchListTile(
          contentPadding:
              const EdgeInsets.only(top: 16, bottom: 8, right: 16, left: 16),
          value: box.get("moreItems", defaultValue: false),
          subtitle: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Duplicate the number of colors in HSLuv/HSV pickers.",
              textAlign: TextAlign.center,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(FeatherIcons.plusCircle),
              const SizedBox(width: 16),
              Text(
                "More Colors",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.title,
              ),
            ],
          ),
          onChanged: (value) {
            box.put('moreItems', value);
          },
        );
      },
    );
  }
}

class ColorCompare extends StatelessWidget {
  const ColorCompare({this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push<dynamic>(
          context,
          MaterialPageRoute<dynamic>(
            builder: (context) => ContrastScreen(color: color),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(FeatherIcons.trendingUp),
                  const SizedBox(width: 16),
                  Text(
                    "Contrast Mode",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.title,
                  ),
                ],
              ),
            ),
            Icon(FeatherIcons.chevronRight),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class GDPR extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return wrapInCard(
      child: Column(
        children: <Widget>[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(FeatherIcons.shield),
              const SizedBox(width: 16),
              Text("Privacy Policy",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.title),
            ],
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "This app respects your privacy.\nThere are no analytics, no data collection. Your colors are yours and no one else will know them.",
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

Widget wrapInCard({@required Widget child}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 850),
    child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      clipBehavior: Clip.antiAlias,
      child: DismissKeyboardOnScroll(child: child),
    ),
  );
}

class _ContactInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        Text("HSLuv Sample",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headline
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text("Designed & developed by Bernardo Ferrari.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.subtitle),
        const SizedBox(height: 8),
        Text("This app is open source",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.caption),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            const SizedBox(width: 32),
            IconButton(
              icon: Icon(FeatherIcons.github),
              tooltip: "GitHub",
              onPressed: () async {
                _launchURL("https://github.com/bernaferrari");
              },
            ),
            IconButton(
                icon: Icon(FeatherIcons.twitter),
                tooltip: "Twitter",
                onPressed: () async {
                  _launchURL("https://twitter.com/bernaferrari");
                }),
            IconButton(
              icon: Icon(FeatherIcons.globe),
              tooltip: "Reddit",
              onPressed: () async {
                _launchURL("https://www.reddit.com/user/bernaferrari");
                // https://github.com/feathericons/feather/issues/274
              },
            ),
            IconButton(
              icon: Icon(FeatherIcons.linkedin),
              tooltip: "LinkedIn",
              onPressed: () async {
                _launchURL(
                    "https://www.linkedin.com/in/bernardo-ferrari-9095a877/");
              },
            ),
            IconButton(
              icon: Icon(FeatherIcons.mail),
              tooltip: "Email",
              onPressed: () async {
                const url =
                    'mailto:bernaferrari2+studio@gmail.com?subject=Color%20Studio%20feedback';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  Scaffold.of(context).hideCurrentSnackBar();
                  const snackBar = SnackBar(
                    content: Text('Error! No email app was found.'),
                  );
                  Scaffold.of(context).showSnackBar(snackBar);
                }
              },
            ),
            const SizedBox(width: 32),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    await launch(url);
  }
}
