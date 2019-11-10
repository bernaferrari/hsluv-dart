import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:hsluv/flutter/hsluvcolor.dart';
import 'package:meta/meta.dart';

@immutable
abstract class ContrastColorState extends Equatable {
  const ContrastColorState();
}

class ContrastColorLoading extends ContrastColorState {
  @override
  String toString() => 'BlindColorsLoading state';

  @override
  List<Object> get props => [];
}

class ContrastColorLoaded extends ContrastColorState {
  const ContrastColorLoaded(
    this.hsvColor1,
    this.rgbColor1,
    this.hsluvColor1,
    this.hsvColor2,
    this.rgbColor2,
    this.hsluvColor2,
  );

  final Color rgbColor1;
  final HSVColor hsvColor1;
  final HSLuvColor hsluvColor1;

  final Color rgbColor2;
  final HSVColor hsvColor2;
  final HSLuvColor hsluvColor2;

  @override
  String toString() => 'BlindColorsLoaded state';

  @override
  List<Object> get props => [
        hsvColor1,
        rgbColor1,
        hsluvColor1,
        hsvColor2,
        rgbColor2,
        hsluvColor2,
      ];
}
