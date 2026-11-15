import 'dart:math' as math;

import 'geometry.dart';
import 'hsluv.dart';

class PickerGeometry {
  PickerGeometry({
    required this.lines,
    required this.vertices,
    required this.angles,
    required this.outerCircleRadius,
    required this.innerCircleRadius,
  });

  List<Line> lines;

  // Ordered such that 1st vertex is intersection between first and
  // second line, 2nd vertex between second and third line etc.
  List<Point> vertices;

  // Angles from origin to corresponding vertex
  List<double> angles;

  // Smallest circle with center at origin such that polygon fits inside
  double outerCircleRadius;

  // Largest circle with center at origin such that it fits inside polygon
  double innerCircleRadius;
}

class _LineIntersection {
  const _LineIntersection({
    required this.line1,
    required this.line2,
    required this.intersectionPoint,
    required this.intersectionPointAngle,
    required this.relativeAngle,
  });

  final int line1;
  final int line2;
  final Point intersectionPoint;
  final double intersectionPointAngle;
  final double relativeAngle;
}

class ColorPicker {
  static PickerGeometry getPickerGeometry(double lightness) {
    // Array of lines
    final lines = Hsluv.getBounds(lightness);
    final numLines = lines.length;
    var outerCircleRadius = 0.0;

    // Find the line closest to origin
    int? closestIndex2;
    double? closestLineDistance;

    for (int i = 0; i < numLines; i += 1) {
      final d = Geometry.distanceLineFromOrigin(lines[i]);
      if (closestLineDistance == null || d < closestLineDistance) {
        closestLineDistance = d;
        closestIndex2 = i;
      }
    }

    final closestLine = lines[closestIndex2!];
    final perpendicularLine =
        Line(slope: 0 - (1 / closestLine.slope), intercept: 0.0);
    final startIntersection =
        Geometry.intersectLineLine(closestLine, perpendicularLine);
    final startingAngle = Geometry.angleFromOrigin(startIntersection);

    final List<_LineIntersection> intersections = [];

    for (int i1 = 0; i1 < numLines - 1; i1 += 1) {
      for (int i2 = i1 + 1; i2 < numLines; i2 += 1) {
        final intersectionPoint =
            Geometry.intersectLineLine(lines[i1], lines[i2]);
        final intersectionPointAngle =
            Geometry.angleFromOrigin(intersectionPoint);
        intersections.add(
          _LineIntersection(
            line1: i1,
            line2: i2,
            intersectionPoint: intersectionPoint,
            intersectionPointAngle: intersectionPointAngle,
            relativeAngle:
                Geometry.normalizeAngle(intersectionPointAngle - startingAngle),
          ),
        );
      }
    }

    intersections.sort((a, b) => a.relativeAngle.compareTo(b.relativeAngle));

    final List<Line> orderedLines = [];
    final List<Point> orderedVertices = [];
    final List<double> orderedAngles = [];

    int currentIndex2 = closestIndex2;

    for (final currentIntersection in intersections) {
      int? nextIndex2;
      if (currentIntersection.line1 == currentIndex2) {
        nextIndex2 = currentIntersection.line2;
      } else if (currentIntersection.line2 == currentIndex2) {
        nextIndex2 = currentIntersection.line1;
      }
      if (nextIndex2 != null) {
        currentIndex2 = nextIndex2;

        orderedLines.add(lines[nextIndex2]);
        orderedVertices.add(currentIntersection.intersectionPoint);
        orderedAngles.add(currentIntersection.intersectionPointAngle);

        final double intersectionPointDistance =
            Geometry.distanceFromOrigin(currentIntersection.intersectionPoint);
        if (intersectionPointDistance > outerCircleRadius) {
          outerCircleRadius = intersectionPointDistance;
        }
      }
    }

    return PickerGeometry(
      lines: orderedLines,
      vertices: orderedVertices,
      angles: orderedAngles,
      outerCircleRadius: outerCircleRadius,
      innerCircleRadius: closestLineDistance!,
    );
  }

  static Point closestPoint(PickerGeometry geometry, Point point) {
    // In order to find the closest line we use the point's angle
    final angle = Geometry.angleFromOrigin(point);
    final numVertices = geometry.vertices.length;
    var smallestRelativeAngle = math.pi * 2;
    var index1 = 0;

    for (int i = 0; i < numVertices; i += 1) {
      final relativeAngle =
          Geometry.normalizeAngle(geometry.angles[i] - angle);
      if (relativeAngle < smallestRelativeAngle) {
        smallestRelativeAngle = relativeAngle;
        index1 = i;
      }
    }

    final index2 = (index1 - 1 + numVertices) % numVertices;
    final closestLine = geometry.lines[index2];

    // Provided point is within the polygon
    if (Geometry.distanceFromOrigin(point) <
        Geometry.lengthOfRayUntilIntersect(angle, closestLine)) {
      return point;
    }

    final Line perpendicularLine =
        Geometry.perpendicularThroughPoint(closestLine, point);
    final Point intersectionPoint =
        Geometry.intersectLineLine(closestLine, perpendicularLine);

    final Point bound1 = geometry.vertices[index1];
    final Point bound2 = geometry.vertices[index2];
    final Point upperBound;
    final Point lowerBound;

    if (bound1.x > bound2.x) {
      upperBound = bound1;
      lowerBound = bound2;
    } else {
      upperBound = bound2;
      lowerBound = bound1;
    }

    final Point borderPoint;
    if (intersectionPoint.x > upperBound.x) {
      borderPoint = upperBound;
    } else if (intersectionPoint.x < lowerBound.x) {
      borderPoint = lowerBound;
    } else {
      borderPoint = intersectionPoint;
    }

    return borderPoint;
  }
}
