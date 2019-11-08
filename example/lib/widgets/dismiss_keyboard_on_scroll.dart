import 'package:flutter/cupertino.dart';

class DismissKeyboardOnScroll extends StatelessWidget {
  const DismissKeyboardOnScroll({Key key, this.child, this.onDismiss})
      : super(key: key);

  final Widget child;
  final Function onDismiss;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (x) {
        if (x.dragDetails == null) {
          return false;
        }

        FocusScope.of(context).unfocus();
        if (onDismiss != null) {
          onDismiss();
        }
        return true;
      },
      child: child,
    );
  }
}
