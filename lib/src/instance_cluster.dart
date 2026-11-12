import 'dart:math' as math;

import 'batch_sorter.dart';
import 'math.dart';

/// Spatial cell + `(shader, material, mesh)` cluster of instanced draw items.
final class CellCluster {
  final int cellX;
  final int cellY;
  final int cellZ;
  final int shaderId;
  final int materialId;
  final int meshId;
  final int indexCount;
  final List<RenderBatchItem> items;
  final BatchVec3 centroid;
  final double boundingRadius;

  const CellCluster({
    required this.cellX,
    required this.cellY,
    required this.cellZ,
    required this.shaderId,
    required this.materialId,
    required this.meshId,
    required this.indexCount,
    required this.items,
    required this.centroid,
    required this.boundingRadius,
  });

  int get instanceCount => items.length;
}

/// Groups compatible draw items into bounded spatial cells for instanced/indirect submission.
final class InstanceClusterBuilder {
  const InstanceClusterBuilder._();

  static List<CellCluster> buildClusters(
    List<RenderBatchItem> items, {
    double cellSize = 16.0,
    int maxInstancesPerCluster = 256,
  }) {
    if (items.isEmpty) return const [];
    final safeCell = math.max(0.5, cellSize);
    final maxPer = math.max(1, maxInstancesPerCluster);

    final buckets = <String, List<RenderBatchItem>>{};
    final meta = <String, (int cx, int cy, int cz, int sh, int mat, int mesh, int idx)>{};

    for (final item in items) {
      final cx = (item.worldPosition.x / safeCell).floor();
      final cy = (item.worldPosition.y / safeCell).floor();
      final cz = (item.worldPosition.z / safeCell).floor();
      final key = '${cx}_${cy}_${cz}_${item.shaderId}_${item.materialId}_${item.meshId}';
      (buckets[key] ??= []).add(item);
      meta[key] ??= (
        cx,
        cy,
        cz,
        item.shaderId,
        item.materialId,
        item.meshId,
        item.indexCount,
      );
    }

    final clusters = <CellCluster>[];
    for (final entry in buckets.entries) {
      final m = meta[entry.key]!;
      final list = entry.value;
      for (var start = 0; start < list.length; start += maxPer) {
        final end = math.min(list.length, start + maxPer);
        final chunk = list.sublist(start, end);
        var sum = BatchVec3.zero;
        for (final it in chunk) {
          sum = sum + it.worldPosition;
        }
        final cent = sum * (1.0 / chunk.length);
        var maxR = 0.0;
        for (final it in chunk) {
          final r = (it.worldPosition - cent).length + it.boundingRadius;
          if (r > maxR) maxR = r;
        }
        clusters.add(
          CellCluster(
            cellX: m.$1,
            cellY: m.$2,
            cellZ: m.$3,
            shaderId: m.$4,
            materialId: m.$5,
            meshId: m.$6,
            indexCount: m.$7,
            items: List.unmodifiable(chunk),
            centroid: cent,
            boundingRadius: maxR,
          ),
        );
      }
    }
    return clusters;
  }
}
