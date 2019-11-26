import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:hsluvsample/contrast/color_with_contrast.dart';

import 'multiple_contrast_color_event.dart';
import 'multiple_contrast_color_state.dart';

class MultipleContrastColorBloc
    extends Bloc<MultipleContrastColorEvent, MultipleContrastColorState> {
  @override
  MultipleContrastColorState get initialState => MultipleContrastColorLoading();

  @override
  Stream<MultipleContrastColorState> mapEventToState(
    MultipleContrastColorEvent event,
  ) async* {
    if (event is MultipleLoadInit) {
      yield* _mapInit(event);
    } else if (event is MCMoveColor) {
      yield* _mapColor(event);
    }
  }

  Stream<MultipleContrastColorState> _mapInit(MultipleLoadInit load) async* {
    final List<ContrastedColor> loadedColors = <ContrastedColor>[];

    for (int i = 0; i < load.colors.length; i++) {
      final initColor = load.colors[0];
      final currentColor = load.colors[i];

      loadedColors.add(
        ContrastedColor(
          currentColor,
          calculateContrast(initColor, currentColor),
        ),
      );
    }

    yield MultipleContrastColorLoaded(loadedColors);
  }

  Stream<MultipleContrastColorState> _mapColor(MCMoveColor load) async* {
    final loadedState = state as MultipleContrastColorLoaded;

    // this is necessary, else you modify the original list but this change
    // is gone when you call yield, so it appears the list didn't change.
    final newList = List<ContrastedColor>.from(loadedState.colorsList);

    final initColor = newList[0].rgbColor;

    newList[load.index] = ContrastedColor(
      load.color,
      calculateContrast(
        load.color,
        initColor,
      ),
    );

    if (load.index == 0) {
      for (int i = 1; i < newList.length; i++) {
        newList[i] = ContrastedColor(
          newList[i].rgbColor,
          calculateContrast(
            newList[i].rgbColor,
            newList[0].rgbColor,
          ),
        );
      }
    }

    yield MultipleContrastColorLoaded(newList);
  }
}
