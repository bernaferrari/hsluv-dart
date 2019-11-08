import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/slider_color/slider_color.dart';

void copyToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));

  Scaffold.of(context).hideCurrentSnackBar();
  final snackBar = SnackBar(content: Text('$text copied'));
  Scaffold.of(context).showSnackBar(snackBar);
}

void colorSelected(BuildContext context, Color color) {
  BlocProvider.of<SliderColorBloc>(context).add(MoveColor(color, true));
}
