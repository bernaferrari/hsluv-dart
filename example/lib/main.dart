import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hsluvsample/mdc/mdc_home.dart';
import 'package:hsluvsample/screens/home.dart';
import 'package:hsluvsample/util/constants.dart';
import 'package:path_provider/path_provider.dart';

import 'blocs/blocs.dart';
import 'contrast/shuffle_color.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await openBox();
  BlocSupervisor.delegate = SimpleBlocDelegate();
  runApp(BoxedApp());
}

Future openBox() async {
  if (!kIsWeb) {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }

  return await Hive.openBox<dynamic>("settings");
}

class BoxedApp extends StatefulWidget {
  @override
  _BoxedAppState createState() => _BoxedAppState();
}

class _BoxedAppState extends State<BoxedApp> {
  SliderColorBloc _sliderBloc;
  ColorBlindBloc colorBlindBloc;

  @override
  void initState() {
    super.initState();
    _sliderBloc = SliderColorBloc()..add(MoveColor(Colors.orange[200], true));
    colorBlindBloc = ColorBlindBloc();
  }

  @override
  void dispose() {
    super.dispose();
    _sliderBloc.close();
    colorBlindBloc.close();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData.from(
      colorScheme: const ColorScheme.dark(
//        surface: Color(0xffffd54f),
          ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<MultipleContrastColorBloc>(
          create: (context) => MultipleContrastColorBloc(_sliderBloc)
            ..add(
              MultipleLoadInit(getShuffledColors()),
            ),
        ),
        BlocProvider<SliderColorBloc>(
          create: (context) => _sliderBloc,
        ),
        BlocProvider<MdcSelectedBloc>(
          create: (context) => MdcSelectedBloc(_sliderBloc, colorBlindBloc),
        ),
        BlocProvider<ColorBlindBloc>(
          create: (context) => colorBlindBloc,
        )
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        routes: {
          "/": (context) {
//            return MultipleContrastScreen(color: Colors.red);
            return Home(initialColor: Colors.orange[200]);
          },
          "/theme": (context) => MDCHome()
        },
        theme: base.copyWith(
          typography: Typography.material2018().copyWith(
            black: Typography.dense2018,
            tall: Typography.tall2018,
            englishLike: Typography.englishLike2018,
          ),
          dialogTheme: base.dialogTheme.copyWith(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
          ),
          buttonTheme: base.buttonTheme.copyWith(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultRadius / 2),
            ),
          ),
          cardTheme: base.cardTheme.copyWith(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(defaultRadius),
            ),
          ),
        ),
      ),
    );
  }
}
