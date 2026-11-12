import 'instance_cluster.dart';

/// Compact GPU indirect/instanced draw command emitted for one [CellCluster].
final class IndirectDrawCommand {
  final int commandIndex;
  final int shaderId;
  final int materialId;
  final int meshId;
  final int indexCountPerInstance;
  final int instanceCount;
  final int firstInstance;

  const IndirectDrawCommand({
    required this.commandIndex,
    required this.shaderId,
    required this.materialId,
    required this.meshId,
    required this.indexCountPerInstance,
    required this.instanceCount,
    required this.firstInstance,
  });
}

/// Batching efficiency summary computed by [IndirectDrawTable.build].
final class IndirectDrawStats {
  final int totalInputObjects;
  final int drawCommandCount;
  final int totalInstances;

  const IndirectDrawStats({
    required this.totalInputObjects,
    required this.drawCommandCount,
    required this.totalInstances,
  });

  double get averageInstancesPerDraw =>
      drawCommandCount == 0 ? 0.0 : totalInstances / drawCommandCount;

  double get drawCallReductionRatio =>
      totalInputObjects == 0 ? 0.0 : 1.0 - (drawCommandCount / totalInputObjects);
}

/// Packs clustered instances into an indexed indirect draw stream and summary stats.
final class IndirectDrawTable {
  final List<IndirectDrawCommand> commands;
  final IndirectDrawStats stats;

  const IndirectDrawTable._(this.commands, this.stats);

  factory IndirectDrawTable.build(List<CellCluster> clusters) {
    final cmds = <IndirectDrawCommand>[];
    var instanceCursor = 0;
    for (var i = 0; i < clusters.length; i++) {
      final c = clusters[i];
      cmds.add(
        IndirectDrawCommand(
          commandIndex: i,
          shaderId: c.shaderId,
          materialId: c.materialId,
          meshId: c.meshId,
          indexCountPerInstance: c.indexCount,
          instanceCount: c.instanceCount,
          firstInstance: instanceCursor,
        ),
      );
      instanceCursor += c.instanceCount;
    }

    return IndirectDrawTable._(
      List.unmodifiable(cmds),
      IndirectDrawStats(
        totalInputObjects: instanceCursor,
        drawCommandCount: cmds.length,
        totalInstances: instanceCursor,
      ),
    );
  }
}
