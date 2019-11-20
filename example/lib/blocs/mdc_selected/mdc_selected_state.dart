import 'dart:ui';

import 'package:equatable/equatable.dart';

abstract class MdcSelectedState extends Equatable {
  const MdcSelectedState();
}

class MDCLoadedState extends MdcSelectedState {
  const MDCLoadedState(this.allItems, this.selected);

  final Map<String, Color> allItems;
  final String selected;

  @override
  String toString() => 'MDCLoadedState state with selected: $selected';

  @override
  List<Object> get props => [allItems, selected];
}
