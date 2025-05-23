![Logo of HSLuv for Dart & Flutter](assets/logo.png)

# HSLuv (and HPLuv) for Dart & Flutter

Dart port of [HSLuv](https://www.hsluv.org) (revision 4) with a [Flutter sample](example). This was a direct conversion of the [reference implementation](https://github.com/hsluv/hsluv/tree/main/haxe).
The sample is available as a web app.

<a href="https://bernaferrari.github.io/hsluv-dart/"><img src="https://github.com/bernaferrari/hsluv-dart/raw/main/assets/try_here.png" height="50"/></a>

[<p align="center"><img src="https://github.com/bernaferrari/hsluv-dart/raw/main/assets/sample_app.jpg?raw=true" width="400"/></p>](example)

> HSLuv is a human-friendly alternative to HSL.

It is like HSL, but color only gets perceptually lighter or darker when the Lightness attribute changes.
In HSL, if you go from a green hue to a red one, there will be big differences in the perceived lightness. In HSLuv, almost none.

If you want to see for yourself, check the [sample app](example) and open the Color Compare screen. Contrast "only" changes when Lightness changes.
When Hue or Saturation attributes change, there might be minimal changes in contrast (in the 0.01 range), but nothing perceivable and certainly better than HSV/HSL.

This is specially useful when [building acessible color systems](https://stripe.com/blog/accessible-color-systems).
For more information, check: [Designing Color Spaces](https://programmingdesignsystems.com/color/perceptually-uniform-color-spaces/index.html) / [Wikipedia article](https://en.wikipedia.org/wiki/HSLuv)

## HPLuv

[<p align="center"><img src="https://github.com/user-attachments/assets/f551a11f-1b57-46d6-af23-e100d22d6f5e?raw=true" width="310"/></p>](hpluv)

H**P**Luv is a similar color space where the perceptual saturation/chroma of a color always stays the same under hue changes. HPL is illustrated by the smaller circle within the [hsluv](https://www.hsluv.org) homepage color picker, which consists of the maximum saturation HPL values available for the given lightness level. HPL is restricted to **P**astel colors, as many hues cannot reach saturation levels that equal the other hues (eg, in the image, at lightness = 60.2, the most saturated cyan is only about half as saturated as the most saturated possible orange, so the maximum saturation of HPL colors there is constrained to that of cyan).

You can make a `Color` in HPLuv with `toColor(Hsluv.hpluvToRgb([hue, saturation, lightness))` where `hue: [0...360]`, `saturation: [0..100]`, `lightness: [0..100]`.

## Usage

In the `pubspec.yaml` of your flutter project, add the following dependency:

[![pub package](https://img.shields.io/pub/v/hsluv.svg)](https://pub.dev/packages/hsluv)

```yaml
dependencies:
  hsluv: ^VERSION
```

In your project you can use it in two different ways, either low level (directly accessing values as a `list<double>`) or high level (similar to [HSLColor](https://api.flutter.dev/flutter/painting/HSLColor-class.html)).
`HSLuvColor` is easier to use, but has less flexibility than a raw list.

```dart
import 'package:hsluv/hsluv.dart';

void main() {

  // Low level usage.
  final List<double> hsluvLow = Hsluv.rgbToHsluv([0.2,0.5,0.7]);
  print(Hsluv.hsluvToHex(hsluvLow));

  // High level usage.
  final hsluvFromColor = HSLuvColor.fromColor(Colors(0xffef3e4a));
  print(hsluvFromColor.toString());

  final hsluvFromHSL = HSLuvColor.fromHSL(300, 70, 60);
  print(hsluvFromHSL.toString());
}
```

[<p align="center"><img src="https://github.com/bernaferrari/hsluv-dart/raw/main/assets/hsv_vs_hsluv.gif?raw=true" width="300"/></p>](example)

[Sample app](example) showing HSV (top) vs HSLuv (bottom). See how the perceived lightness changes as the hue slider moves.

### Color values ranges

- RGB values are ranging in [0...1]
- HSLuv and HPLuv values have different ranging for their components
  - H : [0...360]
  - S and L : [0...100]
- LUV has different ranging for their components
  - L\* : [0...100]
  - u* and v* : [-100...100]
- LCh has different ranging for their components
  - L\* : [0...100]
  - C* : [0...?] Upper bound varies depending on L* and H\*
  - H\* : [0...360]
- XYZ values are ranging in [0...1]

**Important**: Flutter's HSLColor has lightness and saturation ranging from 0 to 1.0. HSLuv uses 0 to 100.
There is a class, called HSInterColor in the [sample](example) that tries to mitigate this.

### API functions

#### Note

The passing/returning values, when not `String` are `List<double>` containing each component of the given color space/system in the name's order :

- RGB : [red, blue, green]
- XYZ : [X, Y, Z]
- LCH : [L, C, H]
- LUV : [L, u, v]
- HSLuv/HPLuv : [H, S, L]

#### Function listing

- `xyzToRgb(List<double> tuple)`
- `rgbToXyz(List<double> tuple)`
- `xyzToLuv(List<double> tuple)`
- `luvToXyz(List<double> tuple)`
- `luvToLch(List<double> tuple)`
- `lchToLuv(List<double> tuple)`
- `hsluvToLch(List<double> tuple)`
- `lchToHsluv(List<double> tuple)`
- `hpluvToLch(List<double> tuple)`
- `lchToHpluv(List<double> tuple)`
- `lchToRgb(List<double> tuple)`
- `rgbToLch(List<double> tuple)`
- `hsluvToRgb(List<double> tuple)`
- `rgbToHsluv(List<double> tuple)`
- `hpluvToRgb(List<double> tuple)`
- `rgbToHpluv(List<double> tuple)`
- `hsluvToHex(List<double> tuple)`
- `hpluvToHex(List<double> tuple)`
- `hexToHsluv(String s)`
- `hexToHpluv(String s)`
- `rgbToHex(List<double> tuple)`
- `hexToRgb(String hex)`

### Reporting Issues

Issues and Pull Requests are welcome.
You can report [here](https://github.com/bernaferrari/hsluv-dart/issues).

### License

```text
Copyright 2020 Bernardo Ferrari

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
