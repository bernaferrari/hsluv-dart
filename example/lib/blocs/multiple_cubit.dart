import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hsluv/hsluvcolor.dart';

import '../contrast/inter_color_with_contrast.dart';
import '../util/color_util.dart';
import 'colors_cubit.dart';

class MultipleContrastCompareCubit extends Cubit<MultipleColorCompareState> {
  MultipleContrastCompareCubit(ColorsCubit colorsCubit)
      : super(const MultipleColorCompareState()) {
    set(
      rgbColors: colorsCubit.state.rgbColors,
      hsluvColors: colorsCubit.state.hsluvColors,
    );

    _mdcSubscription = colorsCubit.stream.listen((stateValue) async {
      set(
        rgbColors: stateValue.rgbColors,
        hsluvColors: stateValue.hsluvColors,
      );
    });
  }

  late StreamSubscription _mdcSubscription;

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
    required Map<int, Color> rgbColors,
    required Map<int, HSLuvColor> hsluvColors,
    int? selectedKey,
  }) {
    final colorsCompared = <int, ColorCompareContrast>{};
    final selectedKey0 = selectedKey ?? state.selectedKey;

    for (var key in rgbColors.keys) {
      if (key == selectedKey0) {
        colorsCompared[key] = ColorCompareContrast.withoutRange(
          rgbColor: rgbColors[key]!,
          hsluvColor: hsluvColors[key]!,
          index: key,
        );
        continue;
      }

      final colorsRange = <RgbHSLuvTupleWithContrast>[];
      for (var i = -10; i < 15; i += 5) {
        final luv = hsluvColors[key]!;

        // if lightness becomes 0 or 100 the hue value might be lost
        // because app is always converting HSLuv to RGB and vice-versa.
        final updatedLuv =
            luv.withLightness(interval(luv.lightness + i, 5.0, 95.0));

        colorsRange.add(
          RgbHSLuvTupleWithContrast(
            rgbColor: updatedLuv.toColor(),
            hsluvColor: updatedLuv,
            againstColor: rgbColors[selectedKey0]!,
          ),
        );
      }

      colorsCompared[key] = ColorCompareContrast(
        rgbColor: rgbColors[key]!,
        hsluvColor: hsluvColors[key]!,
        index: key,
        colorsRange: colorsRange,
        againstColor: rgbColors[selectedKey0]!,
      );
    }

    emit(
      MultipleColorCompareState(
        colorsCompared: colorsCompared,
        originalRgb: rgbColors,
        originalHsluv: hsluvColors,
        selectedKey: selectedKey0,
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
  List<Object?> get props =>
      [selectedKey, colorsCompared, originalRgb, originalHsluv];
}

class ColorCompareContrast extends Equatable {
  ColorCompareContrast({
    required this.rgbColor,
    required this.hsluvColor,
    required this.index,
    required this.colorsRange,
    required Color againstColor,
  }) : contrast = calculateContrast(rgbColor, againstColor);

  const ColorCompareContrast.withoutRange({
    required this.rgbColor,
    required this.hsluvColor,
    required this.index,
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
  List<Object?> get props => [rgbColor, index, contrast, colorsRange];
}

class RgbHSLuvTupleWithContrast extends Equatable {
  RgbHSLuvTupleWithContrast({
    required this.rgbColor,
    required this.hsluvColor,
    required Color againstColor,
  }) : contrast = calculateContrast(rgbColor, againstColor);

  final Color rgbColor;
  final HSLuvColor hsluvColor;
  final double contrast;

  @override
  List<Object?> get props => [rgbColor, hsluvColor, contrast];
}
