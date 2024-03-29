import '../hsinter.dart';

List<HSInterColor> hsinterAlternatives(HSInterColor hsInterColor, [int n = 6]) {
  final int div = (360 / n).round();
  // in the original, code it is: luv.hue + (div * n) % 360
  // this was modified to ignore luv.hue value because the
  // list that is observing would miss the current position every time
  // the color changes.
  return [for (int i = 0; i < n; i++) hsInterColor.withHue((div * i) % 360.0)];
}

List<HSInterColor> hsinterTones(
  HSInterColor hsInterColor,
  int size, [
  double start = 5.0,
  double stop = 100.0,
]) {
  final step = (stop - start) / (size - 1);

  return [
    // this is the only way I found to make it work, from e.g. 95 to 5, inclusive.
    for (int n = size - 1; n >= 0; n -= 1)
      hsInterColor.withSaturation(n * step + start)
  ];
}

List<HSInterColor> hsinterLightness(
  HSInterColor hsInterColor,
  int size, [
  double start = 5.0,
  double stop = 95.0,
]) {
  final step = (stop - start) / (size - 1);

  return [
    // (n = size; n > 0) won't work because n * step will be wrong. Unless you
    // you use (n-1) * step, but then it is an extra calculation per operation.
    for (int n = size - 1; n >= 0; n -= 1)
      hsInterColor.withLightness(n * step + start)
  ];
}
