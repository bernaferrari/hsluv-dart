import 'package:hsluv/hsluv.dart';

class Snapshot {
  static List<String> generateHexSamples() {
    String digits = "0123456789abcdef";
    List<String> ret = [];
    for (int i = 0; i < 16; i += 1) {
      var r = digits[i];
      for (int j = 0; j < 16; j += 1) {
        var g = digits[j];
        for (int k = 0; k < 16; k += 1) {
          var b = digits[k];
          var hex = "#" + r + r + g + g + b + b;
          ret.add(hex);
        }
      }
    }
    return ret;
  }

  static Map<String, Map<String, List<double>>> generateSnapshot() {
    Map<String, Map<String, List<double>>> ret = Map();
    var samples = Snapshot.generateHexSamples();

    for (String hex in samples) {
      var rgb = Hsluv.hexToRgb(hex);
      var xyz = Hsluv.rgbToXyz(rgb);
      var luv = Hsluv.xyzToLuv(xyz);
      var lch = Hsluv.luvToLch(luv);

      Map<String, List<double>> sample = Map();
      sample["rgb"] = rgb;
      sample["xyz"] = xyz;
      sample["luv"] = luv;
      sample["lch"] = lch;
      sample["hsluv"] = Hsluv.lchToHsluv(lch);
      sample["hpluv"] = Hsluv.lchToHpluv(lch);

      ret[hex] = sample;
    }

    return ret;
  }
}
