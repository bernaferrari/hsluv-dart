<p align="center"><img src="https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/ic_launcher-playstore.png" alt="HSLuv Sample" height="200px"></p>

HSLuv Sample for Flutter
===================================

| Sliders | Main Screen | Color Blindness | About |
|:-:|:-:|:-:|:-:|
| ![First](https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/sliders.jpg?raw=true) | ![Sec](https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/main.jpg?raw=true) | ![Third](https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/color-blindness.jpg?raw=true) | ![Fourth](https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/about.jpg?raw=true) |

Most color pickers give you 16 million colors and ask you to choose one. I designed and developed this app to help developers and designers find the best color for them with the smallest amount of effort.

This app is actually part of another one, which is coming out hopefully soon and will also be open source. The project grew so large I thought it was better to split in two, test the public reception and collect feedback before moving forward. This is why this might be one of the most full-fledged over-engineered sample apps out there.
It is hard to develop alone. If you have any good or bad feedback, want to be alerted when the bigger app is released or want to be more involved, [please contact me](mailto:bernaferrari2@gmail.com)!

[Download the APK](https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/hsluv_sample.apk)

This app contains the following screens:
* Three sliders. RGB, HSV and HSLuv. You can see how they interact with each other.
* HSLuv/HSV vertical picker. Shows a lot of colors without being overwhelming.
* About. Contains a button to shuffle colors and a button open the compare colors screen.
* Color Library. Colors from [Color Claim](https://www.vanschneider.com/colors), the color palette from Tobias van Schneider. 
* Compare Colors. Compare the WACG contrast between the first color and all the others. 
* Info. Check how the color attributes are changing from first color to others. Easy to see patterns (i.e. colors are similar but only Hue is changing!) 

## Color Blindness
> Color blindness involves difficulty in perceiving or distinguishing between colors, as well as sensitivity to color brightness. It affects approximately one in twelve men and one in two hundred women worldwide.
> [Carbon Design System](https://www.carbondesignsystem.com/guidelines/accessibility/color#introduction)

| Type           | Color deficiency |
| -------------- | ---------------- |
| _Protanopia_   | Red/green        |
| _Tritanopia_   | Blue             |
| _Deuteranopia_ | Green            |
| _Monochromacy_ | All colors       |

The app calculates color blindness by using the formulas from a Swift library named [Colorblinds](https://github.com/jdekock/Colorblinds).

## Contrast
[WCAG](https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html) specifies:
- **3.0:1** minimum contrast ratio for texts larger than 18pt (AA+).
- **4.5:1** minimum contrast ratio for texts smaller than 18pt (AA).
- **7.0:1** minimum contrast ratio is preferred, when possible (AAA).

The Compare Colors screen will help you check if your color palette is accessible enough.

For more information about those A letters, [see this guide](https://usecontrast.com/guide). [IBM Checkpoint 1.4.3 Contrast (Minimum)](https://www.ibm.com/able/guidelines/ci162/contrast.html).
Google [also follows](https://material.io/design/usability/accessibility.html#color-contrast) these guidelines in Material Design.

## Color Claim
The app uses [Color Claim](https://www.vanschneider.com/colors) as the main palette, both in "Color Library" screen and when shuffling colors.
Every time the method to shuffle the colors is called, it is actually retrieving Color Claim, shuffling it, and getting the first n elements.
This pseudo-randomization strategy guarantees nice colors always. 

To retrieve the colors, I opened the `colorclaim.1.1.sketchpalette` file in Visual Studio Code and took all the hex colors.

| Compare | Info | Color Library |
|:-:|:-:|:-:|
| ![First](https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/compare.jpg?raw=true) | ![Sec](https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/info.jpg?raw=true) | ![Third](https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/library.jpg?raw=true) |

## HSV vs HSLuv
<p align="center"><img src="https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/hsluv_vs_hsv.jpg" alt="HSV vs HSLuv" height="350px"></p>
You can see in that image the difference between Hue values in HSV (or HSL, which has the same Hue values) and HSLuv. HSLuv only changes the apparent lightness when lightness changes.
You can change both Hue and Saturation values that, when compared to another color, the resulting contrast value will be the same. This is one of the foundations for the "Contrast Compare" screen.
You only need to update the lightness value and nothing else to modify the contrast ratio. Therefore, you only need one picker or slider, not three, if you are aiming at the contrast.

## HSInterColor
While developing this app, there was a need to interop HSLuvColor with HSVColor (or HSLColor). Given the similarities but differences between both (HSLuv's Saturation and Lightness range from 0 to 100, instead of 0 to 1.0),
 HSInterColor was born. You pass a kind parameter, which can be HSLuv or HSV and it automatically wraps them, so you can have unified `toString`, `toColor` and others. It is also extensible and modifying it to wrap other color structures should be easy.
 
## Design Process
<p align="center"><img src="https://github.com/bernaferrari/hsluv-dart/raw/master/example/assets/design_process.jpg" alt="Design Process" height="350px"></p>

Many strategies were used to design this app. One of them was to draw in iPad using [Paper by Wetransfer](https://apps.apple.com/us/app/paper-by-wetransfer/id506003812) until a satisfiable design appeared.
Another one was to sometimes test the app in iPad instead of phone. The large rectangular screen would make some designs immediately obsolete. And vice-versa. There was a previous iteration of the Color Compare screen that only compared two colors, but with a lot of details (like 3 selectors for each - H, S and V).
This couldn't fit comfortably a phone's screen and, at the end, the 2 Color Compare screen was replaced by a multi Color Compare. It became more flexible and now works across all screens.

## Why Flutter?
I've been developing with Flutter for the past few months and has been a really enjoyable experience. There are [a lot bugs](https://github.com/flutter/flutter/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc+author%3Abernaferrari), tooling for Dart is miles behind Kotlin, and there was even a feature in this app that had to be disabled because of mutable bugs.
On the good side, it avoided me having to do the same work 3 times and this
 project even lead to [a contribution in Flutter](https://github.com/flutter/flutter/pull/40641), the addition of `onLongPress` in Buttons.

Another fun thing: I needed to clone the Material Slider and modify it to fix [this](https://github.com/flutter/flutter/issues/40310). While not something good (or even expected), it is great that Flutter doesn't use private internal fields in their own libraries.
This could never happen in native Android with Material Components. Everything is tightly coupled. 

While there were many frustrations, bugs, and some things that weren't possible (yet), I am really happy with the result and there would be few benefits if **this** app were native.

### Reporting Issues

Issues and Pull Requests are welcome.
You can report [here](https://github.com/bernaferrari/hsluv-dart/issues).

### License

    Copyright 2019 Bernardo Ferrari

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
