import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:hsluvsample/blocs/slider_color/slider_color_state.dart';
import 'package:hsluvsample/util/constants.dart';
import '../blocs.dart';
import './mdc_selected.dart';

class MdcSelectedBloc extends Bloc<MdcSelectedEvent, MdcSelectedState> {

  MdcSelectedBloc(this._sliderColorsBloc) {
    _slidersSubscription = _sliderColorsBloc.listen((stateValue) async {
      if (stateValue is SliderColorLoaded) {
        add(MDCLoadEvent(
          currentColor: stateValue.rgbColor,
          currentTitle: (state as MDCLoadedState).selected,
          selectedTitle: (state as MDCLoadedState).selected,
        ));
      }
    });
  }

  final SliderColorBloc _sliderColorsBloc;
  StreamSubscription _slidersSubscription;
  final initial = {
    kPrimary: const Color(0xffFFCC80),
    kSurface: const Color(0xff131024),
  };

  @override
  Future<void> close() {
    _slidersSubscription.cancel();
    return super.close();
  }

  @override
  MdcSelectedState get initialState => MDCLoadedState(initial, kPrimary);

  @override
  Stream<MdcSelectedState> mapEventToState(
    MdcSelectedEvent event,
  ) async* {
    if (event is MDCLoadEvent) {
      yield* _mapLoadedToState(event);
    } else if (event is MDCUpdateAllEvent) {
      yield* _mapUpdateAllToState(event);
    }
  }

  Stream<MdcSelectedState> _mapLoadedToState(MDCLoadEvent load) async* {
    final Map<String, Color> updatableMap =
    Map.from((state as MDCLoadedState).allItems);
    updatableMap[load.currentTitle] = load.currentColor;
    yield MDCLoadedState(updatableMap, load.selectedTitle);
  }

  Stream<MdcSelectedState> _mapUpdateAllToState(MDCUpdateAllEvent load) async* {
    final Map<String, Color> updatableMap =
    Map.from((state as MDCLoadedState).allItems);
    updatableMap[kPrimary] = load.primaryColor;
    updatableMap[kSurface] = load.surfaceColor;
    yield MDCLoadedState(updatableMap, load.selectedTitle);
  }
}
