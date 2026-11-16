import 'dart:convert';
import 'dart:io';

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

  /// Loads the canonical 4,096-entry revision 4 snapshot checked in from
  /// upstream `hsluv/hsluv`.
  static Map<String, Map<String, List<double>>> loadCanonicalRev4Snapshot() {
    final file = File('test/snapshot-rev4.json').existsSync()
        ? File('test/snapshot-rev4.json')
        : File('../test/snapshot-rev4.json');
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return decoded.map(
      (hex, entry) => MapEntry(
        hex,
        (entry as Map<String, dynamic>).map(
          (space, coords) => MapEntry(
            space,
            (coords as List<dynamic>)
                .map((value) => (value as num).toDouble())
                .toList(growable: false),
          ),
        ),
      ),
    );
  }
}
