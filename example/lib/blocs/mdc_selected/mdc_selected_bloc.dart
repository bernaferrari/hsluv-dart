import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:hsluvsample/blocs/slider_color/slider_color_state.dart';
import 'package:hsluvsample/dashboard_screen.dart';
import 'package:hsluvsample/util/constants.dart';

import './mdc_selected.dart';
import '../blocs.dart';

class MdcSelectedBloc extends Bloc<MdcSelectedEvent, MdcSelectedState> {
  MdcSelectedBloc(this._sliderColorsBloc, this._blindnessBloc) {
    _slidersSubscription = _sliderColorsBloc.listen((stateValue) async {
      if (stateValue is SliderColorLoaded) {
        add(MDCLoadEvent(
          currentColor: stateValue.rgbColor,
          currentTitle: (state as MDCLoadedState).selected,
          selectedTitle: (state as MDCLoadedState).selected,
        ));
      }
    });

    _blindnessSubscription = _blindnessBloc.listen((stateValue) async {
      add(MDCBlindnessEvent(
        blindnessSelected: stateValue,
      ));
    });
  }

  final ColorBlindBloc _blindnessBloc;
  StreamSubscription _blindnessSubscription;

  final SliderColorBloc _sliderColorsBloc;
  StreamSubscription _slidersSubscription;

  final initial = {
    kPrimary: const Color(0xffFFCC80),
    kSurface: const Color(0xff131024),
  };

  @override
  Future<void> close() {
    _blindnessSubscription.cancel();
    _slidersSubscription.cancel();
    return super.close();
  }

  @override
  MdcSelectedState get initialState =>
      MDCLoadedState(initial, initial, kPrimary, 0);

  @override
  Stream<MdcSelectedState> mapEventToState(
    MdcSelectedEvent event,
  ) async* {
    if (event is MDCLoadEvent) {
      yield* _mapLoadedToState(event);
    } else if (event is MDCUpdateAllEvent) {
      yield* _mapUpdateAllToState(event);
    } else if (event is MDCBlindnessEvent) {
      yield* _mapBlindnessToState(event);
    }
  }

  Stream<MdcSelectedState> _mapLoadedToState(MDCLoadEvent load) async* {
    final Map<String, Color> updatableMap =
        Map.from((state as MDCLoadedState).allItems);
    updatableMap[load.currentTitle] = load.currentColor;

    final blindness = (state as MDCLoadedState).blindnessSelected;

    yield MDCLoadedState(
      updatableMap,
      getBlindness(updatableMap, blindness),
      load.selectedTitle,
      blindness,
    );
  }

  Stream<MdcSelectedState> _mapBlindnessToState(MDCBlindnessEvent load) async* {
    final Map<String, Color> updatableMap = (state as MDCLoadedState).allItems;

    yield MDCLoadedState(
      updatableMap,
      getBlindness(updatableMap, load.blindnessSelected),
      (state as MDCLoadedState).selected,
      load.blindnessSelected,
    );
  }

  Stream<MdcSelectedState> _mapUpdateAllToState(MDCUpdateAllEvent load) async* {
    final Map<String, Color> updatableMap =
        Map.from((state as MDCLoadedState).allItems);
    updatableMap[kPrimary] = load.primaryColor;
    updatableMap[kSurface] = load.surfaceColor;

    final blindness = (state as MDCLoadedState).blindnessSelected;

    yield MDCLoadedState(
      updatableMap,
      getBlindness(updatableMap, blindness),
      load.selectedTitle,
      blindness,
    );
  }

  Map<String, Color> getBlindness(Map<String, Color> updatableMap, int index) {
    if (index == 0) {
      return updatableMap;
    }

    final Map<String, Color> blindMap = Map.from(updatableMap);
    blindMap[kPrimary] =
        getColorBlindFromIndex(blindMap[kPrimary], index).color;
    blindMap[kSurface] =
        getColorBlindFromIndex(blindMap[kSurface], index).color;

    return blindMap;
  }
}
