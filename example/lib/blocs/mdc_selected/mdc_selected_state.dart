import 'dart:ui';

import 'package:equatable/equatable.dart';

abstract class MdcSelectedState extends Equatable {
  const MdcSelectedState();
}

class MDCLoadedState extends MdcSelectedState {
  const MDCLoadedState(
      this.allItems, this.blindness, this.selected, this.blindnessSelected);

  final Map<String, Color> allItems;
  final Map<String, Color> blindness;
  final String selected;
  final int blindnessSelected;

  @override
  String toString() => 'MDCLoadedState state with selected: $selected';

  @override
  List<Object> get props => [allItems, blindness, selected, blindnessSelected];
}
