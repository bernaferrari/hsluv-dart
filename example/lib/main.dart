import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hsluvsample/screen_color_home.dart';

import 'blocs/blocs.dart';
import 'contrast/contrast_screen.dart';

void main() {
  BlocSupervisor.delegate = SimpleBlocDelegate();
  runApp(BoxedApp());
}

class BoxedApp extends StatefulWidget {
  @override
  _BoxedAppState createState() => _BoxedAppState();
}

class _BoxedAppState extends State<BoxedApp> {
  SliderColorBloc _sliderBloc;

  @override
  void initState() {
    super.initState();
    _sliderBloc = SliderColorBloc()..add(MoveColor(Colors.orange[200], true));
  }

  @override
  void dispose() {
    super.dispose();
    _sliderBloc.close();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData.from(
      colorScheme: const ColorScheme.dark(
        surface: Color(0xffffd54f),
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<SliderColorBloc>(
          builder: (context) => _sliderBloc,
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        routes: {
          "/": (context) {
            return ColorHome(initialColor: Colors.orange[200]);
          },
        },
        theme: base.copyWith(
          typography: Typography().copyWith(
            black: Typography.dense2018,
            tall: Typography.tall2018,
            englishLike: Typography.englishLike2018,
          ),
          dialogTheme: base.dialogTheme.copyWith(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          buttonTheme: base.buttonTheme.copyWith(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          cardTheme: base.cardTheme.copyWith(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
