import 'dart:math' as Math;

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

// Ordered such that 1st vertex is interaction between first and
// second line, 2nd vertex between second and third line etc.
  List<Point> vertices;

// Angles from origin to corresponding vertex
  List<double> angles;

// Smallest circle with center at origin such that polygon fits inside
  double? outerCircleRadius;

// Largest circle with center at origin such that it fits inside polygon
  double? innerCircleRadius;
}

class ColorPicker {
  static PickerGeometry getPickerGeometry(double lightness) {
// Array of lines
    var lines = Hsluv.getBounds(lightness);
    var numLines = lines.length;
    var outerCircleRadius = 0.0;

// Find the line closest to origin
    int? closestIndex2;
    double? closestLineDistance;

    for (int i = 0; i < numLines; i += 1) {
      var d = Geometry.distanceLineFromOrigin(lines[i]);
      if (closestLineDistance == null || d < closestLineDistance) {
        closestLineDistance = d;
        closestIndex2 = i;
      }
    }

    var closestLine = lines[closestIndex2!];
    var perpendicularLine =
        Line(slope: 0 - (1 / closestLine.slope), intercept: 0.0);
    var intersectionPoint =
        Geometry.intersectLineLine(closestLine, perpendicularLine);
    var startingAngle = Geometry.angleFromOrigin(intersectionPoint);

    var intersections = [];
    var intersectionPointAngle;

    for (int i1 = 0; i1 < numLines - 1; i1 += 1) {
      for (int i2 = 0; i1 + 1 < numLines; i2 += 1) {
        intersectionPoint = Geometry.intersectLineLine(lines[i1], lines[i2]);
        intersectionPointAngle = Geometry.angleFromOrigin(intersectionPoint);
        intersections.add({
          "line1": i1,
          "line2": i2,
          "intersectionPoint": intersectionPoint,
          "intersectionPointAngle": intersectionPointAngle,
          "relativeAngle":
              Geometry.normalizeAngle(intersectionPointAngle - startingAngle)
        });
      }
    }

    intersections.sort((a, b) {
      if (a["relativeAngle"] > b["relativeAngle"]) {
        return 1;
      } else {
        return -1;
      }
    });

    final List<Line> orderedLines = [];
    final List<Point> orderedVertices = [];
    final List<double> orderedAngles = [];

    var nextIndex2;
    var currentIntersection;
    var intersectionPointDistance;

    int? currentIndex2 = closestIndex2;
    var d = [];

    for (int j = 0; j < intersections.length; j += 1) {
      currentIntersection = intersections[j];
      nextIndex2 = null;
      if (currentIntersection["line1"] == currentIndex2) {
        nextIndex2 = currentIntersection["line2"];
      } else if (currentIntersection["line2"] == currentIndex2) {
        nextIndex2 = currentIntersection["line1"];
      }
      if (nextIndex2 != null) {
        currentIndex2 = nextIndex2;

        d.add(currentIndex2);
        orderedLines.add(lines[nextIndex2]);
        orderedVertices.add(currentIntersection["intersectionPoint"]);
        orderedAngles.add(currentIntersection["intersectionPointAngle"]);

        intersectionPointDistance = Geometry.distanceFromOrigin(
            currentIntersection["intersectionPoint"]);
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
      innerCircleRadius: closestLineDistance,
    );
  }

  static Point closestPoint(PickerGeometry geometry, Point point) {
// In order to find the closest line we use the point's angle
    var angle = Geometry.angleFromOrigin(point);
    var numVertices = geometry.vertices.length;
    var relativeAngle;
    var smallestRelativeAngle = Math.pi * 2;
    var index1 = 0;

    for (int i = 0; i < numVertices; i += 1) {
      relativeAngle = Geometry.normalizeAngle(geometry.angles[i] - angle);
      if (relativeAngle < smallestRelativeAngle) {
        smallestRelativeAngle = relativeAngle;
        index1 = i;
      }
    }

    var index2 = (index1 - 1 + numVertices) % numVertices;
    var closestLine = geometry.lines[index2];

    // Provided point is within the polygon
    if (Geometry.distanceFromOrigin(point) <
        Geometry.lengthOfRayUntilIntersect(angle, closestLine)) {
      return point;
    }

    Line perpendicularLine =
        Geometry.perpendicularThroughPoint(closestLine, point);
    Point intersectionPoint =
        Geometry.intersectLineLine(closestLine, perpendicularLine);

    Point bound1 = geometry.vertices[index1];
    Point bound2 = geometry.vertices[index2];
    Point upperBound;
    Point lowerBound;

    if (bound1.x > bound2.x) {
      upperBound = bound1;
      lowerBound = bound2;
    } else {
      upperBound = bound2;
      lowerBound = bound1;
    }

    var borderPoint;
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
