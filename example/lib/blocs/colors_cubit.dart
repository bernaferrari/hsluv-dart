import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hsluv/hsluvcolor.dart';

import 'blocs.dart';

class ColorsState extends Equatable {
  const ColorsState({
    required this.rgbColors,
    required this.hsluvColors,
    required this.selected,
  });

  final Map<int, Color> rgbColors;
  final Map<int, HSLuvColor> hsluvColors;
  final int selected;

  @override
  String toString() => 'ColorsState with selected: $selected';

  @override
  List<Object> get props => [
        rgbColors,
        hsluvColors,
        selected,
      ];

  ColorsState copyWith({
    Map<int, Color>? rgbColors,
    Map<int, HSLuvColor>? hsluvColors,
    int? selected,
    int? blindnessSelected,
  }) {
    return ColorsState(
      rgbColors: rgbColors ?? this.rgbColors,
      hsluvColors: hsluvColors ?? this.hsluvColors,
      selected: selected ?? this.selected,
    );
  }
}

class ColorsCubit extends Cubit<ColorsState> {
  ColorsCubit(SliderColorBloc _sliderColorBloc, ColorsState initialState)
      : super(initialState) {
    _sliderColorBlocSubscription =
        _sliderColorBloc.stream.listen((stateValue) async {
      if (stateValue is SliderColorLoaded) {
        updateColor(
          rgbColor: stateValue.rgbColor,
          hsLuvColor: stateValue.hsluvColor,
        );
      }
    });
  }

  late StreamSubscription _sliderColorBlocSubscription;

  @override
  Future<void> close() {
    _sliderColorBlocSubscription.cancel();
    return super.close();
  }

  /// This method retrieves a ColorState which is going to be used in super().
  /// The reason is undo/redo support. First ColorCubit value can't be empty.
  static ColorsState initialState(List<Color> initialColors) {
    final colorsMap = <int, Color>{};
    for (int i = 0; i < initialColors.length; i++) {
      colorsMap[i] = initialColors[i];
    }

    return ColorsState(
      rgbColors: colorsMap,
      hsluvColors: _convertToHSLuv(colorsMap),
      selected: 0,
    );
  }

  void updateColor({
    int? selected,
    Color? rgbColor,
    HSLuvColor? hsLuvColor,
  }) {
    assert(rgbColor != null || hsLuvColor != null);

    final _selected = selected ?? state.selected;

    final allLuv = Map<int, HSLuvColor>.from(state.hsluvColors);
    final allRgb = Map<int, Color>.from(state.rgbColors);

    if (rgbColor != null && hsLuvColor != null) {
      allLuv[_selected] = hsLuvColor;
      allRgb[_selected] = rgbColor;
    } else if (rgbColor != null) {
      allLuv[_selected] = HSLuvColor.fromColor(rgbColor);
      allRgb[_selected] = rgbColor;
    } else {
      allLuv[_selected] = hsLuvColor!;
      allRgb[_selected] = hsLuvColor.toColor();
    }

    emit(
      state.copyWith(
        rgbColors: allRgb,
        hsluvColors: allLuv,
        selected: _selected,
      ),
    );
  }

  void updateRgbColor({int? selected, required Color rgbColor}) {
    final _selected = selected ?? state.selected;

    final allRgb = Map<int, Color>.from(state.rgbColors);
    allRgb[_selected] = rgbColor;

    emit(
      state.copyWith(
        rgbColors: allRgb,
        hsluvColors: _convertToHSLuv(allRgb),
        selected: _selected,
      ),
    );
  }

  void updateSelected(int selection) =>
      emit(state.copyWith(selected: selection));

  void updateAllColors({required List<Color> colors}) {
    final colorsMap = <int, Color>{};
    for (int i = 0; i < colors.length; i++) {
      colorsMap[i] = colors[i];
    }

    emit(
      state.copyWith(
        rgbColors: colorsMap,
        hsluvColors: _convertToHSLuv(colorsMap),
      ),
    );
  }

  static Map<int, HSLuvColor> _convertToHSLuv(Map<int, Color> updatableMap) {
    final luvMap = <int, HSLuvColor>{};

    for (var key in updatableMap.keys) {
      luvMap[key] = HSLuvColor.fromColor(updatableMap[key]!);
    }

    return luvMap;
  }
}
