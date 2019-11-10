import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:hsluv/flutter/hsluvcolor.dart';
import 'package:hsluvsample/blocs/contrast_color/contrast_color_state.dart';
import 'package:rxdart/rxdart.dart';

import 'contrast_color_event.dart';

class ContrastColorBloc extends Bloc<ContrastColorEvent, ContrastColorState> {
  @override
  ContrastColorState get initialState => ContrastColorLoading();

  @override
  Stream<ContrastColorState> transformEvents(events, next) {
    return (events as Observable<ContrastColorEvent>).switchMap(next);
  }

  @override
  Stream<ContrastColorState> mapEventToState(
    ContrastColorEvent event,
  ) async* {
    if (event is LoadInit) {
      yield* _mapInit(event);
    } else if (event is CMoveRGB) {
      yield* _mapRGB(event);
    }
    if (event is CMoveHSV) {
      yield* _mapHSV(event);
    }
    if (event is CMoveHSLuv) {
      yield* _mapHSLuv(event);
    }
    if (event is CMoveColor) {
      yield* _mapColor(event);
    }
  }

  Stream<ContrastColorState> _mapInit(LoadInit load) async* {
    yield ContrastColorLoaded(
      HSVColor.fromColor(load.color1),
      load.color1,
      HSLuvColor.fromColor(load.color1),
      HSVColor.fromColor(load.color2),
      load.color2,
      HSLuvColor.fromColor(load.color2),
    );
  }

  Stream<ContrastColorState> _mapHSLuv(CMoveHSLuv load) async* {
    final loadedState = state as ContrastColorLoaded;

    final hsluv = HSLuvColor.fromHSL(load.h, load.s, load.l);
    final color = hsluv.toColor();

    if (load.isFirst) {
      yield ContrastColorLoaded(
        HSVColor.fromColor(color),
        color,
        hsluv,
        loadedState.hsvColor2,
        loadedState.rgbColor2,
        loadedState.hsluvColor2,
      );
    } else {
      yield ContrastColorLoaded(
        loadedState.hsvColor1,
        loadedState.rgbColor1,
        loadedState.hsluvColor1,
        HSVColor.fromColor(color),
        color,
        hsluv,
      );
    }
  }

  Stream<ContrastColorState> _mapHSV(CMoveHSV load) async* {
    final loadedState = state as ContrastColorLoaded;

    final hsv = HSVColor.fromAHSV(1, load.h, load.s, load.v);
    final color = hsv.toColor();

    if (load.isFirst) {
      yield ContrastColorLoaded(
        hsv,
        color,
        HSLuvColor.fromColor(color),
        loadedState.hsvColor2,
        loadedState.rgbColor2,
        loadedState.hsluvColor2,
      );
    } else {
      yield ContrastColorLoaded(
        loadedState.hsvColor1,
        loadedState.rgbColor1,
        loadedState.hsluvColor1,
        hsv,
        color,
        HSLuvColor.fromColor(color),
      );
    }
  }

  Stream<ContrastColorState> _mapRGB(CMoveRGB load) async* {
    final loadedState = state as ContrastColorLoaded;
    final rgb = Color.fromARGB(255, load.r, load.g, load.b);

    if (load.isFirst) {
      yield ContrastColorLoaded(
        HSVColor.fromColor(rgb),
        rgb,
        HSLuvColor.fromColor(rgb),
        loadedState.hsvColor2,
        loadedState.rgbColor2,
        loadedState.hsluvColor2,
      );
    } else {
      yield ContrastColorLoaded(
        loadedState.hsvColor1,
        loadedState.rgbColor1,
        loadedState.hsluvColor1,
        HSVColor.fromColor(rgb),
        rgb,
        HSLuvColor.fromColor(rgb),
      );
    }
  }

  Stream<ContrastColorState> _mapColor(CMoveColor load) async* {
    final loadedState = state as ContrastColorLoaded;

    if (load.isFirst) {
      yield ContrastColorLoaded(
        HSVColor.fromColor(load.color),
        load.color,
        HSLuvColor.fromColor(load.color),
        loadedState.hsvColor2,
        loadedState.rgbColor2,
        loadedState.hsluvColor2,
      );
    } else {
      yield ContrastColorLoaded(
        loadedState.hsvColor1,
        loadedState.rgbColor1,
        loadedState.hsluvColor1,
        HSVColor.fromColor(load.color),
        load.color,
        HSLuvColor.fromColor(load.color),
      );
    }
  }
}
