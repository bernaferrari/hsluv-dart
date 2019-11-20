import 'package:flutter/material.dart';
import 'package:hsluvsample/widgets/dismiss_keyboard_on_scroll.dart';

class WidgetWithSelector extends StatelessWidget {
  const WidgetWithSelector({this.child, this.selector});

  final Widget child;
  final Widget selector;

  @override
  Widget build(BuildContext context) {
    if (selector == null) {
      return wrapInCard(child: child);
    }

    return Column(
      children: <Widget>[Expanded(child: wrapInCard(child: child)), selector],
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
