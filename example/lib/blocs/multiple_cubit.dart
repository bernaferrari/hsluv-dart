import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hsluv/hsluvcolor.dart';

import '../contrast/inter_color_with_contrast.dart';
import '../util/color_util.dart';
import 'colors_cubit.dart';

class MultipleContrastCompareCubit extends Cubit<MultipleColorCompareState> {
  MultipleContrastCompareCubit(ColorsCubit _colorsCubit)
      : super(const MultipleColorCompareState()) {
    set(
      rgbColors: _colorsCubit.state.rgbColors,
      hsluvColors: _colorsCubit.state.hsluvColors,
    );

    _mdcSubscription = _colorsCubit.listen((stateValue) async {
      set(
        rgbColors: stateValue.rgbColors,
        hsluvColors: stateValue.hsluvColors,
      );
    });
  }

  StreamSubscription _mdcSubscription;

  @override
  Future<void> close() {
    _mdcSubscription.cancel();
    return super.close();
  }

  void updateSelectedKey(int selected) => set(
        rgbColors: state.originalRgb,
        hsluvColors: state.originalHsluv,
        selectedKey: selected,
      );

  void set({
    Map<int, Color> rgbColors,
    Map<int, HSLuvColor> hsluvColors,
    Map locked,
    int selectedKey,
  }) {
    final colorsCompared = <int, ColorCompareContrast>{};
    final _selectedKey = selectedKey ?? state.selectedKey;

    for (var key in rgbColors.keys) {
      if (key == _selectedKey) {
        colorsCompared[key] = ColorCompareContrast.withoutRange(
          rgbColor: rgbColors[key],
          hsluvColor: hsluvColors[key],
          index: key,
        );
        continue;
      }

      final colorsRange = <RgbHSLuvTupleWithContrast>[];
      for (var i = -10; i < 15; i += 5) {
        final luv = hsluvColors[key];

        // if lightness becomes 0 or 100 the hue value might be lost
        // because app is always converting HSLuv to RGB and vice-versa.
        final updatedLuv =
            luv.withLightness(interval(luv.lightness + i, 5.0, 95.0));

        colorsRange.add(
          RgbHSLuvTupleWithContrast(
            rgbColor: updatedLuv.toColor(),
            hsluvColor: updatedLuv,
            againstColor: rgbColors[_selectedKey],
          ),
        );
      }

      colorsCompared[key] = ColorCompareContrast(
        rgbColor: rgbColors[key],
        hsluvColor: hsluvColors[key],
        index: key,
        colorsRange: colorsRange,
        againstColor: rgbColors[_selectedKey],
      );
    }

    emit(
      MultipleColorCompareState(
        colorsCompared: colorsCompared,
        originalRgb: rgbColors,
        originalHsluv: hsluvColors,
        selectedKey: _selectedKey,
      ),
    );
  }
}

class MultipleColorCompareState extends Equatable {
  const MultipleColorCompareState({
    this.selectedKey = 0,
    this.colorsCompared = const {},
    this.originalRgb = const {},
    this.originalHsluv = const {},
  });

  final Map<int, Color> originalRgb;
  final Map<int, HSLuvColor> originalHsluv;

  final Map<int, ColorCompareContrast> colorsCompared;
  final int selectedKey;

  @override
  String toString() =>
      'MultipleColorCompareState($selectedKey, $colorsCompared)';

  @override
  List<Object> get props =>
      [selectedKey, colorsCompared, originalRgb, originalHsluv];
}

class ColorCompareContrast extends Equatable {
  ColorCompareContrast({
    @required this.rgbColor,
    @required this.hsluvColor,
    @required this.index,
    @required this.colorsRange,
    @required Color againstColor,
  }) : contrast = calculateContrast(rgbColor, againstColor);

  const ColorCompareContrast.withoutRange({
    @required this.rgbColor,
    @required this.hsluvColor,
    @required this.index,
    this.colorsRange = const [],
    this.contrast = 0,
  });

  final int index;
  final Color rgbColor;
  final HSLuvColor hsluvColor;
  final double contrast;
  final List<RgbHSLuvTupleWithContrast> colorsRange;

  @override
  String toString() => 'ColorCompareContrast($index: $rgbColor)';

  @override
  List<Object> get props => [rgbColor, index, contrast, colorsRange];
}

class RgbHSLuvTupleWithContrast extends Equatable {
  RgbHSLuvTupleWithContrast(
      {this.rgbColor, this.hsluvColor, Color againstColor})
      : contrast = calculateContrast(rgbColor, againstColor);

  final Color rgbColor;
  final HSLuvColor hsluvColor;
  final double contrast;

  @override
  List<Object> get props => [rgbColor, hsluvColor, contrast];
}
