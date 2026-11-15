import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hsluv/hsluvcolor.dart';
import 'package:hsluvsample/blocs/studio_cubit.dart';
import 'package:hsluvsample/main.dart';
import 'package:hsluvsample/models/accessibility_utils.dart';
import 'package:hsluvsample/models/color_spaces.dart';
import 'package:hsluvsample/widgets/slide_picker_column.dart';
import 'package:hsluvsample/widgets/studio_theme.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Color math & StudioCubit unit tests', () {
    test('OklchColor round-trips sRGB colors accurately', () {
      const samples = [
        Color(0xFF00A8E8),
        Color(0xFFFF5A5F),
        Color(0xFF10B981),
        Color(0xFFF59E0B),
        Color(0xFF8B5CF6),
        Color(0xFF222222),
        Color(0xFFFAFAFA),
      ];

      for (final sample in samples) {
        final oklch = OklchColor.fromColor(sample);
        final back = oklch.toColor();
        final dr = ((sample.r - back.r) * 255).abs();
        final dg = ((sample.g - back.g) * 255).abs();
        final db = ((sample.b - back.b) * 255).abs();
        expect(dr, lessThanOrEqualTo(2));
        expect(dg, lessThanOrEqualTo(2));
        expect(db, lessThanOrEqualTo(2));
      }
    });

    test('solveHsluvForContrast finds AA and AAA compliant lightness', () {
      const lightYellow = HSLuvColor.fromHSL(75, 95, 88);
      final aa = solveHsluvForContrast(lightYellow, Colors.white, 4.5);
      final aaa = solveHsluvForContrast(lightYellow, Colors.white, 7.0);

      expect(aa, isNotNull);
      expect(wcagContrastRatio(aa!.toColor(), Colors.white), greaterThanOrEqualTo(4.5));
      expect(aaa, isNotNull);
      expect(wcagContrastRatio(aaa!.toColor(), Colors.white), greaterThanOrEqualTo(7.0));
    });

    test('StudioCubit scrub lifecycle updates live and folds into single undo', () {
      final cubit = StudioCubit();
      final initialHex = cubit.state.activeColor.hex;

      cubit.beginScrub();
      cubit.scrubChannel(0, 120.0);
      final midHex = cubit.state.activeColor.hex;
      expect(midHex, isNot(equals(initialHex)));

      cubit.scrubChannel(0, 240.0);
      final secondHex = cubit.state.activeColor.hex;
      expect(secondHex, isNot(equals(midHex)));

      cubit.endScrub();
      expect(cubit.state.canUndo, isTrue);

      cubit.undo();
      expect(cubit.state.activeColor.hex, equals(initialHex));
      expect(cubit.state.canRedo, isTrue);

      cubit.redo();
      expect(cubit.state.activeColor.hex, equals(secondHex));
      cubit.close();
    });
  });

  group('StudioApp widget tests', () {
    void configureViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('dragging SlidePickerColumn updates value live mid-drag in Silk & Wave modes', (tester) async {
      configureViewport(tester);
      final cubit = StudioCubit();

      await tester.pumpWidget(StudioApp(cubit: cubit));
      await tester.pumpAndSettle();

      // Switch to Silk (continuous) mode first (starts in Wave stepped mode)
      await tester.tap(find.text('Silk'));
      await tester.pumpAndSettle();
      expect(cubit.state.isSteppedMode, isFalse);

      final initialColor = cubit.state.activeColor;
      final initialHex = initialColor.hex;
      expect(find.text(initialHex), findsOneWidget);

      // Find the Lightness column (3rd column) and start a live vertical drag
      final lightnessCol = find.byType(SlidePickerColumn).at(2);
      final center = tester.getCenter(lightnessCol);

      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 75));
      await tester.pump();

      // Active hex MUST already change while dragging BEFORE lifting finger!
      final midDragHex = cubit.state.activeColor.hex;
      expect(midDragHex, isNot(equals(initialHex)));
      expect(find.text(midDragHex), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(cubit.state.activeColor.hex, equals(midDragHex));

      // Switch back to Wave mode and confirm sliding updates live mid-drag!
      await tester.tap(find.text('Wave'));
      await tester.pumpAndSettle();
      expect(cubit.state.isSteppedMode, isTrue);

      final beforeSteppedHex = cubit.state.activeColor.hex;
      final hueCol = find.byType(SlidePickerColumn).at(0);
      final hueCenter = tester.getCenter(hueCol);
      final steppedGesture = await tester.startGesture(hueCenter);
      await tester.pump();
      await steppedGesture.moveBy(const Offset(0, 25));
      await tester.pump();
      await steppedGesture.moveBy(const Offset(0, 95));
      await tester.pump();

      expect(cubit.state.activeColor.hex, isNot(equals(beforeSteppedHex)));
      await steppedGesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('switching color spaces and flinging 2D ColorStage canvas works cleanly', (tester) async {
      configureViewport(tester);
      final cubit = StudioCubit();

      await tester.pumpWidget(StudioApp(cubit: cubit));
      await tester.pumpAndSettle();

      // Switch to OKLCH in stage space pill bar
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPillSelector<ColorSpaceMode>),
          matching: find.text('OKLCH'),
        ),
      );
      await tester.pumpAndSettle();
      expect(cubit.state.activeSpace, equals(ColorSpaceMode.oklch));
      expect(find.text('CHROMA'), findsOneWidget);

      // Switch to HCT in stage space pill bar
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPillSelector<ColorSpaceMode>),
          matching: find.text('HCT'),
        ),
      );
      await tester.pumpAndSettle();
      expect(cubit.state.activeSpace, equals(ColorSpaceMode.hct));
      expect(find.text('TONE'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SlidePickerColumn).at(2),
          matching: find.text('TONE'),
        ),
        findsOneWidget,
      );

      // Drag and fling directly on the 2D pigment stage canvas
      final stageCanvas = find.byKey(const ValueKey('stage_2d_canvas'));
      expect(stageCanvas, findsOneWidget);

      final beforeStageHex = cubit.state.activeColor.hex;
      final beforeHue = cubit.state.activeColor.hctHue;
      await tester.fling(stageCanvas, const Offset(130, -80), 950);
      await tester.pumpAndSettle();
      expect(cubit.state.activeColor.hex, isNot(equals(beforeStageHex)));
      expect(cubit.state.activeColor.hctHue, isNot(equals(beforeHue)));
    });

    testWidgets('navigates Reels, Spectrum, and Palette lenses cleanly', (tester) async {
      configureViewport(tester);
      final cubit = StudioCubit();
      await tester.pumpWidget(StudioApp(cubit: cubit));
      await tester.pumpAndSettle();

      // Navigate to Spectrum lens
      await tester.tap(find.text('Spectrum'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('spectrum_gesture_canvas')), findsOneWidget);
      expect(find.text('HSL'), findsOneWidget);

      // Fling Spectrum horizontally
      await tester.fling(
        find.byKey(const ValueKey<String>('spectrum_gesture_canvas')),
        const Offset(-180, -40),
        900,
      );
      await tester.pumpAndSettle();

      // Navigate to Palette lens
      await tester.tap(find.text('Palette'));
      await tester.pumpAndSettle();
      expect(find.text('50'), findsOneWidget);
      expect(find.text('950'), findsOneWidget);
      expect(find.text('Analogous'), findsOneWidget);
      expect(find.text('Complementary'), findsOneWidget);
      expect(find.text('Triadic'), findsOneWidget);
      expect(find.text('Split'), findsOneWidget);
      expect(find.text('Copy HEX'), findsOneWidget);
      expect(find.text('Copy CSS oklch()'), findsOneWidget);

      // Tapping Triadic chord pours new colors into the stage palette wells
      final beforePalette = cubit.state.palette.map((c) => c.hex).toList();
      await tester.tap(find.text('Triadic'));
      await tester.pumpAndSettle();
      final afterPalette = cubit.state.palette.map((c) => c.hex).toList();
      expect(afterPalette, isNot(equals(beforePalette)));
    });

    testWidgets('unblemished Wave track tap snaps cleanly and Space shuffles', (tester) async {
      configureViewport(tester);
      final cubit = StudioCubit();

      await tester.pumpWidget(StudioApp(cubit: cubit));
      await tester.pumpAndSettle();

      final initialLightness = cubit.state.activeColor.hsluv.lightness.round();
      final lightnessCol = find.byType(SlidePickerColumn).at(2);

      // Unselected tiles carry no ruler text clutter (only the selected numeral in header + active stripe)
      expect(
        find.descendant(of: lightnessCol, matching: find.text('80%')),
        findsNothing,
      );

      // Tap near top-quarter of Lightness track (high lightness stripe)
      final rect = tester.getRect(lightnessCol);
      await tester.tapAt(Offset(rect.center.dx, rect.top + 180));
      await tester.pumpAndSettle();

      final snappedLightness = cubit.state.activeColor.hsluv.lightness.round();
      expect(snappedLightness % 10, equals(0));
      expect((snappedLightness - initialLightness).abs(), greaterThanOrEqualTo(10));

      final beforeShuffle = cubit.state.palette.map((c) => c.hex).toList();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      final afterShuffle = cubit.state.palette.map((c) => c.hex).toList();
      expect(afterShuffle, isNot(equals(beforeShuffle)));
    });

    testWidgets('ballistic fling on Hue reel spins Hue with momentum', (tester) async {
      configureViewport(tester);
      final cubit = StudioCubit();

      await tester.pumpWidget(StudioApp(cubit: cubit));
      await tester.pumpAndSettle();

      final beforeFlingHue = cubit.state.activeColor.hsluv.hue;
      final beforeFlingHex = cubit.state.activeColor.hex;

      await tester.fling(
        find.byType(SlidePickerColumn).at(0),
        const Offset(0, -250),
        1200,
      );
      await tester.pumpAndSettle();

      expect(cubit.state.activeColor.hex, isNot(equals(beforeFlingHex)));
      expect(
        (cubit.state.activeColor.hsluv.hue - beforeFlingHue).abs(),
        greaterThan(5.0),
      );
    });
  });
}
