import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:hsluv/flutter/hsluvcolor.dart';
import 'package:hsluvsample/contrast/color_with_contrast.dart';
import 'package:meta/meta.dart';

import '../../dashboard_screen.dart';

@immutable
abstract class MultipleContrastColorState extends Equatable {
  const MultipleContrastColorState();
}

class MultipleContrastColorLoading extends MultipleContrastColorState {
  @override
  String toString() => 'BlindColorsLoading state';

  @override
  List<Object> get props => [];
}

class MultipleContrastColorLoaded extends MultipleContrastColorState {
  const MultipleContrastColorLoaded(this.colorsList);

  final List<ContrastedColor> colorsList;

  @override
  String toString() => 'BlindColorsLoaded state $colorsList';

  @override
  List<Object> get props => [colorsList];
}

class ContrastedColor {
  ContrastedColor(this.rgbColor, this.contrast)
      : hsluvColor = HSLuvColor.fromColor(rgbColor);

  final Color rgbColor;
  final double contrast;
  final HSLuvColor hsluvColor;

  @override
  String toString() => "$rgbColor";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContrastedColor &&
          runtimeType == other.runtimeType &&
          rgbColor == other.rgbColor;

  @override
  int get hashCode => rgbColor.hashCode;
}
