import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../blocs/blocs.dart';
import '../contrast/shuffle_color.dart';
import '../util/constants.dart';

class About extends StatelessWidget {
  const About({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 818),
        child: ListView(
          key: const PageStorageKey("about"),
          shrinkWrap: true,
          children: const <Widget>[
            Padding(padding: EdgeInsets.all(4)),
            TranslucentCard(
              child: _ContactInfo(),
            ),
            TranslucentCard(
              child: ColorCompare(),
            ),
            TranslucentCard(
              child: ShuffleSection(),
            ),
            TranslucentCard(
              child: GDPR(),
            ),
            Padding(padding: EdgeInsets.all(4)),
          ],
        ),
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  const _ContactInfo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        Text("HSLuv Sample",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall!
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text("Designed & developed by Bernardo Ferrari.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text("If you have ideas or suggestions, please get in touch!",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: 8),
        Text("This app is open source.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            const SizedBox(width: 32),
            IconButton(
              icon: const Icon(FeatherIcons.github),
              tooltip: "GitHub",
              onPressed: () async {
                _launchURL("https://github.com/bernaferrari");
              },
            ),
            IconButton(
                icon: const Icon(FeatherIcons.twitter),
                tooltip: "Twitter",
                onPressed: () async {
                  _launchURL("https://twitter.com/bernaferrari");
                }),
            IconButton(
              icon: const Icon(FeatherIcons.tag),
              tooltip: "Reddit",
              onPressed: () async {
                _launchURL("https://www.reddit.com/user/bernaferrari");
                // unfortunately at this moment there is no icon for Reddit.
                // I thought 'tag' is better than 'message-square'.
                // https://github.com/feathericons/feather/issues/274
              },
            ),
            IconButton(
              icon: const Icon(FeatherIcons.linkedin),
              tooltip: "LinkedIn",
              onPressed: () async {
                _launchURL(
                    "https://www.linkedin.com/in/bernardo-ferrari-9095a877/");
              },
            ),
            IconButton(
              icon: const Icon(FeatherIcons.mail),
              tooltip: "Email",
              onPressed: () async {
                const url =
                    'mailto:bernaferrari2+studio@gmail.com?subject=Color%20Studio%20feedback';
                if (await canLaunchUrl(Uri.https(url))) {
                  await launchUrl(Uri.https(url));
                } else {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  const snackBar = SnackBar(
                    content: Text('Error! No email app was found.'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
    await launchUrl(Uri.https(url));
  }
}

class ColorCompare extends StatelessWidget {
  const ColorCompare({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, "compare"),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(FeatherIcons.trendingUp),
                  const SizedBox(width: 16),
                  Text(
                    "Compare Colors",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Icon(FeatherIcons.chevronRight),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class ShuffleSection extends StatelessWidget {
  const ShuffleSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context
          .read<ColorsCubit>()
          .updateAllColors(colors: getShuffledColors()),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(FeatherIcons.shuffle),
                  const SizedBox(width: 16),
                  Text(
                    "Shuffle colors",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Icon(FeatherIcons.chevronRight),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class MoreColors extends StatelessWidget {
  const MoreColors({required this.activeColor, Key? key}) : super(key: key);

  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<dynamic>>(
      valueListenable: Hive.box<dynamic>("settings").listenable(),
      builder: (context, box, _) {
        return SwitchListTile(
          contentPadding:
              const EdgeInsets.only(top: 8, bottom: 8, right: 16, left: 16),
          value: box.get("moreItems", defaultValue: false)!,
          activeColor: activeColor,
          subtitle: Text(
            "Duplicate the number of colors in HSLuv/HSV pickers.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          title: Text(
            "More Colors",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          onChanged: (value) {
            box.put('moreItems', value);
          },
        );
      },
    );
  }
}

class GDPR extends StatelessWidget {
  const GDPR({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(FeatherIcons.shield),
            const SizedBox(width: 16),
            Text("Privacy Policy",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
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
    );
  }
}

class TranslucentCard extends StatelessWidget {
  const TranslucentCard({
    this.child,
    this.margin = const EdgeInsets.only(left: 16, right: 16, top: 8),
    Key? key,
  }) : super(key: key);

  final Widget? child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(2 * kVeryTransparent)),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .background
          .withOpacity(kVeryTransparent),
      margin: margin,
      child: child,
    );
  }
}
