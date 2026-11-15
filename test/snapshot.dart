import 'package:hsluv/hsluv.dart';

class Snapshot {
  static List<String> generateHexSamples() {
    const digits = "0123456789abcdef";
    final List<String> ret = [];
    for (int i = 0; i < 16; i += 1) {
      final r = digits[i];
      for (int j = 0; j < 16; j += 1) {
        final g = digits[j];
        for (int k = 0; k < 16; k += 1) {
          final b = digits[k];
          final hex = "#$r$r$g$g$b$b";
          ret.add(hex);
        }
      }
    }
    return ret;
  }

  static Map<String, Map<String, List<double>>> generateSnapshot() {
    final Map<String, Map<String, List<double>>> ret = {};
    final samples = Snapshot.generateHexSamples();

    for (final String hex in samples) {
      final rgb = Hsluv.hexToRgb(hex);
      final xyz = Hsluv.rgbToXyz(rgb);
      final luv = Hsluv.xyzToLuv(xyz);
      final lch = Hsluv.luvToLch(luv);

      final Map<String, List<double>> sample = {};
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
