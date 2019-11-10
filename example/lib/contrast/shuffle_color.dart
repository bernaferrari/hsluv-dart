import 'dart:ui';

import 'package:hsluvsample/contrast/color_with_contrast.dart';

class _ColorContrast {
  const _ColorContrast(this.color, this.contrast);

  final Color color;
  final double contrast;
}

Color shuffleColor(Color currentColor) {
  final contrasts = colorClaim.map((i) {
    final color = Color(int.parse("0xFF$i"));
    return _ColorContrast(color, calculateContrast(color, currentColor));
  }).toList();

  final count =
      contrasts.fold(0, (int t, e) => t + ((e.contrast > 3.0) ? 1 : 0));
  if (count < 5) {
    contrasts.shuffle();
    return contrasts.first.color;
  } else {
    final restrictedList = contrasts.where((c) => c.contrast > 3.0).toList()
      ..shuffle();
    return restrictedList.first.color;
  }
}

// https://www.vanschneider.com/colors
const List<String> colorClaim = [
  "FF8B8B",
  "F9F7E8",
  "61BFAD",
  "E54B4B",
  "167C80",
  "B7E3E4",
  "EFE8D8",
  "005397",
  "32B67A",
  "FACA0C",
  "F3C9DD",
  "0BBCD6",
  "BFB5D7",
  "BEA1A5",
  "F0CF61",
  "0E38B1",
  "A6CFE2",
  "371722",
  "C7C6C4",
  "DABAAE",
  "DB9AAD",
  "F1C3B8",
  "EF3E4A",
  "C0C2CE",
  "EEC0DB",
  "B6CAC0",
  "C5BEAA",
  "FDF06F",
  "EDB5BD",
  "17C37B",
  "2C3979",
  "1B1D1C",
  "E88565",
  "FFEFE5",
  "F4C7EE",
  "77EEDF",
  "E57066",
  "EED974",
  "FBFE56",
  "A7BBC3",
  "3C485E",
  "055A5B",
  "178E96",
  "D3E8E1",
  "CBA0AA",
  "9C9CDD",
  "20AD65",
  "E75153",
  "4F3A4B",
  "112378",
  "A82B35",
  "FEDCCC",
  "00B28B",
  "9357A9",
  "C6D7C7",
  "B1FDEB",
  "BEF6E9",
  "776EA7",
  "EAEAEA",
  "EF303B",
  "1812D6",
  "FFFDE7",
  "D1E9E3",
  "7DE0E6",
  "3A745F",
  "CE7182",
  "340B0B",
  "F8EBEE",
  "FF9966",
  "002CFC",
  "75FFC0",
  "FB9B2A",
  "FF8FA4",
  "000000",
  "083EA7",
  "674B7C",
  "19AAD1",
  "12162D",
  "121738",
  "0C485E",
  "FC3C2D",
  "864BFF",
  "EF5B09",
  "97B8A3",
  "FFD101",
  "C26B6A",
  "E3E3E3",
  "FF4C06",
  "CDFF06",
  "0C485E",
  "1F3B34",
  "384D9D",
  "E10000",
  "F64A00",
  "89937A",
  "C39D63",
  "00FDFF",
  "B18AE0",
  "96D0FF",
  "3C225F",
  "FF6B61",
  "EEB200"
];
