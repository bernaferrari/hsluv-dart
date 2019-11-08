import 'package:flutter_test/flutter_test.dart';
import 'test_class.dart';

void main() {
  test("test hsluv", () {
    TestClass.testHsluv();
  });

  test("test consistency", () {
    TestClass.testConsistency();
  });

  test("test channel", () {
    TestClass.testRgbChannelBounds();
  });
}
