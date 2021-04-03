import 'package:bloc/bloc.dart';

// We can extend `BlocDelegate` and override `onTransition` and `onError`
// in order to handle transitions and errors from all Blocs.
class SimpleBlocObserver extends BlocObserver {
  // @override
  // void onEvent(Cubit cubit, Object event) {
  //   print('${cubit.runtimeType} $event');
  //   super.onEvent(cubit, event);
  // }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    print('${bloc.runtimeType} $transition');
    super.onTransition(bloc, transition);
  }

  // @override
  // void onError(Cubit cubit, Object error, StackTrace stackTrace) {
  //   print('${cubit.runtimeType} $error $stackTrace');
  //   super.onError(cubit, error, stackTrace);
  // }
}
