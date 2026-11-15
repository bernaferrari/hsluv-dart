import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'blocs/studio_cubit.dart';
import 'screens/studio_home.dart';
import 'widgets/studio_theme.dart';

void main() {
  runApp(const StudioApp());
}

/// Root Material 3 Perceptual Color Studio application showcasing
/// HSLuv alongside OKLCH and Material 3 HCT.
class StudioApp extends StatelessWidget {
  const StudioApp({super.key, this.cubit});

  final StudioCubit? cubit;

  @override
  Widget build(BuildContext context) {
    const studioSeed = Color(0xFF6366F1);
    return BlocProvider<StudioCubit>(
      create: (_) => cubit ?? StudioCubit(),
      child: BlocBuilder<StudioCubit, StudioState>(
        buildWhen: (prev, next) => prev.themeMode != next.themeMode,
        builder: (context, state) {
          return MaterialApp(
            title: 'Chroma Folio',
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: buildStudioTheme(Brightness.light, studioSeed),
            darkTheme: buildStudioTheme(Brightness.dark, studioSeed),
            home: const StudioHome(),
          );
        },
      ),
    );
  }
}
