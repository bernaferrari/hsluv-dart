## [1.3.0]

* Add `HsluvConverter` for allocation-free, reusable scalar conversions and route `Hsluv` static helpers through it so math lives in one place without intermediate `List`/`Line` allocations.
* Clamp floating-point boundary overshoot on `hsluvToRgb`, `hpluvToRgb`, `rgbToHsluv`, `rgbToHpluv` (`H` and `L`, keeping `S` unclamped for out-of-gamut sRGB round-trips), and `rgbToHex` channels (`0..255`).
* Validate `#RRGGBB` format in `Hsluv.hexToRgb` and throw `FormatException` on malformed hex strings.
* Verify conversions against the canonical 4,096-entry upstream `snapshot-rev4.json` fixture, expand Dartdoc to zero warnings, and refresh README visualizations.

## [1.2.0]

* Require Flutter 3.50+ / Dart 3.14+ (uses `dart:ui` floating-point `Color` channels, compatible with standalone `material_ui` and bundled Flutter apps).
* Export `HSLuvColor`, extensions, `ColorPicker`, `Contrast`, and `Geometry` directly from `package:hsluv/hsluv.dart`.
* Add `HSLuvColor.fromRawColor`, `toRawHSLuv()`, and `round:` option on `HSLuvColor.fromColor` / `toHSLuv()`.
* Fix `ColorPicker.getPickerGeometry` gamut polygon sampling.
* Deprecate the bundled Flutter example in favor of [Chroma Folio](https://github.com/bernaferrari/chroma-folio).

## [1.1.3]
* Update constraints to Flutter 2.19.

## [1.1.2]
* Remove not null assert, which is not necessary anymore.

## [1.1.1]
* Minor fixes related to null safety.

## [1.1.0]
* Add null safety.

## [1.0.6]
* Add addHue, addSaturation, addLightness, addHSLuv methods.

## [1.0.5+1]
* Fix lightness and saturation documentation. It was saying they range from [0, 1] instead of [0, 100].

## [1.0.5]
* Remove additional "(" in toString method from HSLuvColor.

## [1.0.4] 
* Initial port of HSLuv with a nice sample app.
