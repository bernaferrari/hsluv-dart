import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

import '../models/accessibility_utils.dart';
import '../models/color_spaces.dart';

enum PickerViewMode {
  columns('Columns', Icons.view_column_rounded),
  gamut2D('2D Gamut', Icons.track_changes_rounded),
  split('Split', Icons.vertical_split_rounded);

  const PickerViewMode(this.label, this.icon);

  final String label;
  final IconData icon;
}

class StudioState extends Equatable {
  const StudioState({
    required this.palette,
    required this.lockedSlots,
    required this.selectedIndex,
    required this.activeSpace,
    required this.pickerViewMode,
    required this.isSteppedMode,
    required this.stepCount,
    required this.focusedColumn,
    required this.expandColumnOnSlide,
    required this.contrastRefColor,
    required this.showContrastOverlay,
    required this.themeMode,
    required this.undoStack,
    required this.redoStack,
  });

  factory StudioState.initial() {
    return StudioState(
      palette: defaultStudioPalette(),
      lockedSlots: const {},
      selectedIndex: 0,
      activeSpace: ColorSpaceMode.hsluv,
      pickerViewMode: PickerViewMode.split,
      isSteppedMode: true,
      stepCount: 10,
      focusedColumn: null,
      expandColumnOnSlide: false,
      contrastRefColor: Colors.white,
      showContrastOverlay: false,
      themeMode: ThemeMode.light,
      undoStack: const [],
      redoStack: const [],
    );
  }

  final List<StudioColor> palette;
  final Set<int> lockedSlots;
  final int selectedIndex;
  final ColorSpaceMode activeSpace;
  final PickerViewMode pickerViewMode;
  final bool isSteppedMode;
  final int stepCount;
  final int? focusedColumn;
  final bool expandColumnOnSlide;
  final Color contrastRefColor;
  final bool showContrastOverlay;
  final ThemeMode themeMode;
  final List<List<StudioColor>> undoStack;
  final List<List<StudioColor>> redoStack;

  StudioColor get activeColor => palette[selectedIndex];
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  StudioState copyWith({
    List<StudioColor>? palette,
    Set<int>? lockedSlots,
    int? selectedIndex,
    ColorSpaceMode? activeSpace,
    PickerViewMode? pickerViewMode,
    bool? isSteppedMode,
    int? stepCount,
    int? Function()? focusedColumn,
    bool? expandColumnOnSlide,
    Color? contrastRefColor,
    bool? showContrastOverlay,
    ThemeMode? themeMode,
    List<List<StudioColor>>? undoStack,
    List<List<StudioColor>>? redoStack,
  }) {
    return StudioState(
      palette: palette ?? this.palette,
      lockedSlots: lockedSlots ?? this.lockedSlots,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      activeSpace: activeSpace ?? this.activeSpace,
      pickerViewMode: pickerViewMode ?? this.pickerViewMode,
      isSteppedMode: isSteppedMode ?? this.isSteppedMode,
      stepCount: stepCount ?? this.stepCount,
      focusedColumn:
          focusedColumn != null ? focusedColumn() : this.focusedColumn,
      expandColumnOnSlide: expandColumnOnSlide ?? this.expandColumnOnSlide,
      contrastRefColor: contrastRefColor ?? this.contrastRefColor,
      showContrastOverlay: showContrastOverlay ?? this.showContrastOverlay,
      themeMode: themeMode ?? this.themeMode,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }

  @override
  List<Object?> get props => [
        palette,
        lockedSlots,
        selectedIndex,
        activeSpace,
        pickerViewMode,
        isSteppedMode,
        stepCount,
        focusedColumn,
        expandColumnOnSlide,
        contrastRefColor,
        showContrastOverlay,
        themeMode,
        undoStack,
        redoStack,
      ];
}

class StudioCubit extends Cubit<StudioState> {
  StudioCubit() : super(StudioState.initial());

  List<StudioColor>? _scrubSnapshot;
  static const int _maxHistory = 30;

  void selectSlot(int index) {
    if (index < 0 || index >= state.palette.length) return;
    emit(state.copyWith(selectedIndex: index));
  }

  void toggleLockSlot(int index) {
    final updated = Set<int>.from(state.lockedSlots);
    if (!updated.add(index)) {
      updated.remove(index);
    }
    emit(state.copyWith(lockedSlots: updated));
  }

  void setActiveColor(StudioColor color, {bool recordHistory = true}) {
    final updated = List<StudioColor>.from(state.palette);
    if (updated[state.selectedIndex] == color) return;
    final undo = recordHistory
        ? _pushUndo(state.undoStack, state.palette)
        : state.undoStack;
    updated[state.selectedIndex] = color;
    emit(
      state.copyWith(
        palette: updated,
        undoStack: undo,
        redoStack: recordHistory ? const [] : state.redoStack,
      ),
    );
  }

  void beginScrub({int? columnIndex}) {
    _scrubSnapshot = List<StudioColor>.from(state.palette);
    if (state.expandColumnOnSlide && columnIndex != null) {
      emit(state.copyWith(focusedColumn: () => columnIndex));
    }
  }

  void scrubChannel(int channelIndex, double newValue) {
    final updatedColor =
        state.activeColor.withChannelValue(state.activeSpace, channelIndex, newValue);
    setActiveColor(updatedColor, recordHistory: false);
  }

  void scrubHsluvHueSat(double hue, double saturation) {
    final updatedColor = StudioColor.fromHsluv(
      state.activeColor.hsluv.copyWith(hue: hue, saturation: saturation),
    );
    setActiveColor(updatedColor, recordHistory: false);
  }

  void scrubTwoChannels({
    required int xChannel,
    required double xValue,
    required int yChannel,
    required double yValue,
  }) {
    final step1 =
        state.activeColor.withChannelValue(state.activeSpace, xChannel, xValue);
    final step2 = step1.withChannelValue(state.activeSpace, yChannel, yValue);
    setActiveColor(step2, recordHistory: false);
  }

  void endScrub() {
    final snap = _scrubSnapshot;
    _scrubSnapshot = null;
    if (snap != null && snap[state.selectedIndex] != state.activeColor) {
      emit(
        state.copyWith(
          undoStack: _pushUndo(state.undoStack, snap),
          redoStack: const [],
          focusedColumn:
              state.expandColumnOnSlide ? () => null : null,
        ),
      );
    } else if (state.expandColumnOnSlide && state.focusedColumn != null) {
      emit(state.copyWith(focusedColumn: () => null));
    }
  }

  void setSpaceMode(ColorSpaceMode mode) {
    emit(state.copyWith(activeSpace: mode));
  }

  void setPickerViewMode(PickerViewMode mode) {
    emit(state.copyWith(pickerViewMode: mode));
  }

  void setSteppedMode(bool isStepped) {
    emit(state.copyWith(isSteppedMode: isStepped));
  }

  void setStepCount(int count) {
    emit(state.copyWith(stepCount: count));
  }

  void toggleFocusedColumn(int columnIndex) {
    final next = state.focusedColumn == columnIndex ? null : columnIndex;
    emit(state.copyWith(focusedColumn: () => next));
  }

  void toggleExpandColumnOnSlide() {
    final next = !state.expandColumnOnSlide;
    emit(
      state.copyWith(
        expandColumnOnSlide: next,
        focusedColumn: next ? null : () => null,
      ),
    );
  }

  void setShowContrastOverlay(bool show) {
    emit(state.copyWith(showContrastOverlay: show));
  }

  void setContrastRefColor(Color color) {
    emit(state.copyWith(contrastRefColor: color));
  }

  void toggleThemeMode() {
    final next = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    emit(state.copyWith(themeMode: next));
  }

  void shuffleUnlockedColors() {
    final seedHue = math.Random().nextDouble() * 360.0;
    final fresh = generateHarmoniousPalette(seedHue);
    final updated = [
      for (int i = 0; i < state.palette.length; i++)
        state.lockedSlots.contains(i) ? state.palette[i] : fresh[i],
    ];
    emit(
      state.copyWith(
        palette: updated,
        undoStack: _pushUndo(state.undoStack, state.palette),
        redoStack: const [],
      ),
    );
  }

  void applyColorsToPalette(List<StudioColor> colors) {
    final updated = List<StudioColor>.from(state.palette);
    var srcIdx = 0;
    for (int i = 0; i < updated.length && srcIdx < colors.length; i++) {
      if (!state.lockedSlots.contains(i)) {
        updated[i] = colors[srcIdx++];
      }
    }
    emit(
      state.copyWith(
        palette: updated,
        undoStack: _pushUndo(state.undoStack, state.palette),
        redoStack: const [],
      ),
    );
  }

  bool fixActiveColorContrast(double targetRatio, {Color? against}) {
    final ref = against ?? state.contrastRefColor;
    final solved = solveHsluvForContrast(
      state.activeColor.hsluv,
      ref,
      targetRatio,
    );
    if (solved == null) return false;
    setActiveColor(StudioColor.fromHsluv(solved));
    return true;
  }

  void undo() {
    if (state.undoStack.isEmpty) return;
    final prev = state.undoStack.last;
    final nextUndo = state.undoStack.sublist(0, state.undoStack.length - 1);
    final nextRedo = [...state.redoStack, state.palette];
    emit(
      state.copyWith(
        palette: prev,
        undoStack: nextUndo,
        redoStack: nextRedo,
      ),
    );
  }

  void redo() {
    if (state.redoStack.isEmpty) return;
    final next = state.redoStack.last;
    final nextRedo = state.redoStack.sublist(0, state.redoStack.length - 1);
    final nextUndo = [...state.undoStack, state.palette];
    emit(
      state.copyWith(
        palette: next,
        undoStack: nextUndo,
        redoStack: nextRedo,
      ),
    );
  }

  List<List<StudioColor>> _pushUndo(
    List<List<StudioColor>> stack,
    List<StudioColor> snapshot,
  ) {
    final next = [...stack, snapshot];
    if (next.length > _maxHistory) {
      return next.sublist(next.length - _maxHistory);
    }
    return next;
  }
}
