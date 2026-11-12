import 'dart:math' as math;

/// Lightweight platform-neutral 3D vector for draw-call batching and clustering.
final class BatchVec3 {
  final double x;
  final double y;
  final double z;

  const BatchVec3(this.x, this.y, this.z);

  static const BatchVec3 zero = BatchVec3(0.0, 0.0, 0.0);

  BatchVec3 operator +(BatchVec3 other) =>
      BatchVec3(x + other.x, y + other.y, z + other.z);

  BatchVec3 operator -(BatchVec3 other) =>
      BatchVec3(x - other.x, y - other.y, z - other.z);

  BatchVec3 operator *(double s) => BatchVec3(x * s, y * s, z * s);

  double get lengthSquared => x * x + y * y + z * z;
  double get length => math.sqrt(lengthSquared);
}
