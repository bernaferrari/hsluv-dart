import 'dart:ui';

import 'package:equatable/equatable.dart';

abstract class MdcSelectedEvent extends Equatable {
  const MdcSelectedEvent();
}

class MDCLoadEvent extends MdcSelectedEvent {
  const MDCLoadEvent(
      {this.currentColor, this.currentTitle, this.selectedTitle});

  final Color currentColor;
  final String currentTitle;
  final String selectedTitle;

  @override
  String toString() =>
      "MDCLoadEvent... cColor: $currentColor cTitle $currentTitle sTitle $selectedTitle";

  @override
  List<Object> get props => [currentColor, currentTitle, selectedTitle];
}

class MDCUpdateAllEvent extends MdcSelectedEvent {
  const MDCUpdateAllEvent(
      {this.primaryColor, this.surfaceColor, this.selectedTitle});

  final Color primaryColor;
  final Color surfaceColor;
  final String selectedTitle;

  @override
  String toString() =>
      "MDCLoadEvent... cColor: $primaryColor cTitle $surfaceColor sTitle $selectedTitle";

  @override
  List<Object> get props => [primaryColor, surfaceColor, selectedTitle];
}
