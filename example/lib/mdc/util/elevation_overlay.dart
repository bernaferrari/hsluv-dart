final elevationEntries = [
  ElevationOverlay(0, 0.00),
  ElevationOverlay(1, 0.05),
  ElevationOverlay(2, 0.07),
  ElevationOverlay(3, 0.08),
  ElevationOverlay(4, 0.09),
  ElevationOverlay(6, 0.11),
  ElevationOverlay(8, 0.12),
  ElevationOverlay(12, 0.14),
  ElevationOverlay(16, 0.15),
  ElevationOverlay(24, 0.16),
];

const elevationEntriesList = [
  0.0,
  1.0,
  2.0,
  3.0,
  4.0,
  6.0,
  8.0,
  12.0,
  16.0,
  24.0
];

class ElevationOverlay {
  ElevationOverlay(this.elevation, this.overlay);

  final double elevation;
  final double overlay;
}
