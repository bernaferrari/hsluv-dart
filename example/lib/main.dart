import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import 'blocs/blocs.dart';
import 'contrast/shuffle_color.dart';
import 'screen_colors_compare/colors_compare_screen.dart';
import 'screens/home.dart';
import 'util/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await openBox();
  Bloc.observer = SimpleBlocObserver();
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
  SliderColorBloc _sliderColorBloc;
  ColorsCubit _colorsCubit;

  @override
  void initState() {
    super.initState();

    _sliderColorBloc = SliderColorBloc()
      ..add(MoveColor(Colors.orange[200], true));
    _colorsCubit = ColorsCubit(
      _sliderColorBloc,
      ColorsCubit.initialState(getShuffledColors()),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _sliderColorBloc.close();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData base = ThemeData.from(
      colorScheme: const ColorScheme.dark(),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<SliderColorBloc>(
          create: (context) => _sliderColorBloc,
        ),
        BlocProvider<ColorsCubit>(
          create: (context) => _colorsCubit,
        ),
      ],
      child: MaterialApp(
        title: 'HSLuv Sample',
        routes: {
          "/": (context) {
            return Home(initialColor: Colors.orange[200]);
          },
          "compare": (context) {
            return BlocProvider<MultipleContrastCompareCubit>(
              create: (context) => MultipleContrastCompareCubit(_colorsCubit),
              child: ColorsCompareScreen(),
            );
          }
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
