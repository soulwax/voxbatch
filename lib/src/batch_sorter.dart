import 'math.dart';

/// Renderable object descriptor fed into [RenderBatchSorter].
final class RenderBatchItem {
  final int entityId;
  final int shaderId;
  final int materialId;
  final int meshId;
  final int indexCount;
  final double boundingRadius;
  final BatchVec3 worldPosition;
  final double viewDistance;
  final bool transparent;

  const RenderBatchItem({
    required this.entityId,
    required this.shaderId,
    required this.materialId,
    required this.meshId,
    this.indexCount = 36,
    this.boundingRadius = 0.5,
    this.worldPosition = BatchVec3.zero,
    this.viewDistance = 0.0,
    this.transparent = false,
  });
}

/// Result returned by [RenderBatchSorter.sort] with eliminated state-switch metrics.
final class BatchSortResult {
  final List<RenderBatchItem> sortedItems;
  final int stateSwitchesBefore;
  final int stateSwitchesAfter;

  const BatchSortResult({
    required this.sortedItems,
    required this.stateSwitchesBefore,
    required this.stateSwitchesAfter,
  });

  int get switchesEliminated => stateSwitchesBefore - stateSwitchesAfter;
}

/// Sorts draw items to minimize shader/material/mesh state changes while preserving transparent order.
final class RenderBatchSorter {
  const RenderBatchSorter._();

  static int _countStateSwitches(List<RenderBatchItem> items) {
    if (items.length <= 1) return 0;
    var switches = 0;
    for (var i = 1; i < items.length; i++) {
      final a = items[i - 1];
      final b = items[i];
      if (a.shaderId != b.shaderId ||
          a.materialId != b.materialId ||
          a.meshId != b.meshId) {
        switches++;
      }
    }
    return switches;
  }

  static BatchSortResult sort(List<RenderBatchItem> items) {
    final before = _countStateSwitches(items);
    final opaques = <RenderBatchItem>[];
    final transparents = <RenderBatchItem>[];
    for (final item in items) {
      if (item.transparent) {
        transparents.add(item);
      } else {
        opaques.add(item);
      }
    }

    opaques.sort((a, b) {
      final sc = a.shaderId.compareTo(b.shaderId);
      if (sc != 0) return sc;
      final mc = a.materialId.compareTo(b.materialId);
      if (mc != 0) return mc;
      final meshC = a.meshId.compareTo(b.meshId);
      if (meshC != 0) return meshC;
      return a.viewDistance.compareTo(b.viewDistance);
    });

    transparents.sort((a, b) => b.viewDistance.compareTo(a.viewDistance));

    final sorted = [...opaques, ...transparents];
    return BatchSortResult(
      sortedItems: sorted,
      stateSwitchesBefore: before,
      stateSwitchesAfter: _countStateSwitches(sorted),
    );
  }
}
