import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';

@immutable
abstract class ContrastColorEvent extends Equatable {
  const ContrastColorEvent();
}

class LoadInit extends ContrastColorEvent {
  const LoadInit(this.color1, this.color2);

  final Color color1;
  final Color color2;

  @override
  String toString() => "LoadInit...";

  @override
  List<Object> get props => [color1, color2];
}

// all classes get C in front of them to differentiate from SliderColorBloc.
class CMoveColor extends ContrastColorEvent {
  const CMoveColor(this.color, this.isFirst);

  final Color color;
  final bool isFirst;

  @override
  String toString() => "MoveColor...";

  @override
  List<Object> get props => [color];
}

class CMoveRGB extends ContrastColorEvent {
  const CMoveRGB(this.r, this.g, this.b, this.isFirst);

  final int r;
  final int g;
  final int b;
  final bool isFirst;

  @override
  String toString() => "MoveRGB...";

  @override
  List<Object> get props => [r, g, b, isFirst];
}

class CMoveHSV extends ContrastColorEvent {
  const CMoveHSV(this.h, this.s, this.v, this.isFirst) : super();

  final double h;
  final double s;
  final double v;
  final bool isFirst;

  @override
  String toString() => "MoveHSV...";

  @override
  List<Object> get props => [h, s, v, isFirst];
}

class CMoveHSLuv extends ContrastColorEvent {
  const CMoveHSLuv(this.h, this.s, this.l, this.isFirst) : super();

  final double h;
  final double s;
  final double l;
  final bool isFirst;

  @override
  String toString() => "MoveHSL...";

  @override
  List<Object> get props => [h, s, l, isFirst];
}
