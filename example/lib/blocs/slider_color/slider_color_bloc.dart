import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:hsluvsample/blocs/slider_color/slider_color_state.dart';
import 'package:rxdart/rxdart.dart';

import 'slider_color_event.dart';

class SliderColorBloc extends Bloc<SliderColorEvent, SliderColorState> {

  @override
  SliderColorState get initialState => SliderColorLoading();

  @override
  Stream<SliderColorState> transformEvents(events, next) {
    return (events as Observable<SliderColorEvent>).switchMap(next);
  }

  @override
  Stream<SliderColorState> mapEventToState(SliderColorEvent event,
  ) async* {
    if (event is MoveRGB) {
      yield* _mapRGB(event);
    }
    if (event is MoveHSV) {
      yield* _mapHSV(event);
    }
    if (event is MoveHSL) {
      yield* _mapHSL(event);
    }
    if (event is MoveColor) {
      yield* _mapColor(event);
    }
  }

  Stream<SliderColorState> _mapHSL(MoveHSL load) async* {
    final hsl = HSLColor.fromAHSL(1, load.h, load.s, load.l);
    final color = hsl.toColor();
    yield SliderColorLoaded(HSVColor.fromColor(color), color, hsl, true);
  }

  Stream<SliderColorState> _mapHSV(MoveHSV load) async* {
    final hsv = HSVColor.fromAHSV(1, load.h, load.s, load.v);
    final color = hsv.toColor();
    yield SliderColorLoaded(
      hsv,
      color,
      HSLColor.fromColor(color),
      true,
    );
  }

  Stream<SliderColorState> _mapRGB(MoveRGB load) async* {
    final rgb = Color.fromARGB(255, load.r, load.g, load.b);
    yield SliderColorLoaded(
      HSVColor.fromColor(rgb),
      rgb,
      HSLColor.fromColor(rgb),
      true,
    );
  }

  Stream<SliderColorState> _mapColor(MoveColor load) async* {
    yield SliderColorLoaded(
      HSVColor.fromColor(load.color),
      load.color,
      HSLColor.fromColor(load.color),
      load.updateTextField,
    );
  }
}
