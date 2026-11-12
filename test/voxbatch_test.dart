import 'package:test/test.dart';
import 'package:voxbatch/voxbatch.dart';

void main() {
  test('RenderBatchSorter minimizes shader/material switches and keeps transparent back-to-front', () {
    const items = [
      RenderBatchItem(entityId: 1, shaderId: 1, materialId: 1, meshId: 1, viewDistance: 10.0),
      RenderBatchItem(entityId: 2, shaderId: 2, materialId: 3, meshId: 1, viewDistance: 5.0),
      RenderBatchItem(entityId: 3, shaderId: 1, materialId: 1, meshId: 1, viewDistance: 4.0),
      RenderBatchItem(entityId: 4, shaderId: 3, materialId: 4, meshId: 2, viewDistance: 12.0, transparent: true),
      RenderBatchItem(entityId: 5, shaderId: 3, materialId: 4, meshId: 2, viewDistance: 20.0, transparent: true),
    ];

    final res = RenderBatchSorter.sort(items);
    expect(res.switchesEliminated, greaterThan(0));
    expect(res.sortedItems.take(2).map((e) => e.entityId), [3, 1]);
    // Transparents last, sorted far-to-near (entity 5 @ 20m before entity 4 @ 12m)
    expect(res.sortedItems[3].entityId, 5);
    expect(res.sortedItems[4].entityId, 4);
  });

  test('InstanceClusterBuilder buckets nearby matching objects into bounded spatial cell clusters', () {
    final items = [
      for (var i = 0; i < 6; i++)
        RenderBatchItem(
          entityId: i,
          shaderId: 1,
          materialId: 10,
          meshId: 20,
          worldPosition: BatchVec3(i * 0.5, 0.0, 0.0),
        ),
      const RenderBatchItem(
        entityId: 99,
        shaderId: 1,
        materialId: 10,
        meshId: 20,
        worldPosition: BatchVec3(40.0, 0.0, 0.0),
      ),
    ];

    final clusters = InstanceClusterBuilder.buildClusters(
      items,
      cellSize: 10.0,
      maxInstancesPerCluster: 4,
    );
    // Cell (0,0,0) has 6 items -> split into 2 chunks (4 + 2), Cell (4,0,0) has 1 item -> total 3 clusters
    expect(clusters.length, 3);
    expect(clusters.fold<int>(0, (s, c) => s + c.instanceCount), 7);
  });

  test('IndirectDrawTable packs instanced draw commands and computes draw call reduction ratio', () {
    final items = List.generate(
      12,
      (i) => RenderBatchItem(
        entityId: i,
        shaderId: 1,
        materialId: 1,
        meshId: i.isEven ? 1 : 2,
        indexCount: 36,
        worldPosition: const BatchVec3(1.0, 0.0, 1.0),
      ),
    );
    final clusters = InstanceClusterBuilder.buildClusters(items, cellSize: 16.0);
    final table = IndirectDrawTable.build(clusters);

    expect(table.commands.length, 2);
    expect(table.commands[0].firstInstance, 0);
    expect(table.commands[1].firstInstance, 6);
    expect(table.stats.totalInputObjects, 12);
    expect(table.stats.drawCallReductionRatio, closeTo(10.0 / 12.0, 1e-6));
  });
}
