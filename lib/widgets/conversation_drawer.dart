import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:graphview/GraphView.dart';
import '../controllers/chat_controller.dart';
import 'package:graphview/GraphView.dart' show Node;

class ConversationDrawer extends StatelessWidget {
  final ChatController controller = Get.find();

  ConversationDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          AppBar(
            title: const Text('Conversation Graph'),
            automaticallyImplyLeading: false,
            elevation: 0,
          ),
          Expanded(
            child: Obx(() {
              final graphData = controller.getGraphData();
              final adjacencyList =
                  graphData['adjacencyList'] as Map<String, List<String>>;
              final nodeLabels = graphData['nodeLabels'] as Map<String, String>;

              if (adjacencyList.isEmpty) {
                return const Center(
                  child: Text('No conversation yet...'),
                );
              }

              return _buildGraph(context, adjacencyList, nodeLabels);
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Long press any message to create a branch',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                      'Total nodes: ${controller.nodes.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph(
    BuildContext context,
    Map<String, List<String>> adjacencyList,
    Map<String, String> nodeLabels,
  ) {
    final graph = Graph()..isTree = true;
    final theme = Theme.of(context);

    // Add nodes
    final nodeMap = <String, Node>{};
    for (final nodeId in adjacencyList.keys) {
      final node = Node.Id(nodeId);
      nodeMap[nodeId] = node;
      graph.addNode(node);
    }

    // Add edges
    for (final entry in adjacencyList.entries) {
      final parentId = entry.key;
      final children = entry.value;

      for (final childId in children) {
        if (nodeMap.containsKey(childId)) {
          graph.addEdge(nodeMap[parentId]!, nodeMap[childId]!);
        }
      }
    }

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(100),
      minScale: 0.1,
      maxScale: 2.0,
      child: GraphView(
        graph: graph,
        algorithm: BuchheimWalkerAlgorithm(
          BuchheimWalkerConfiguration()
            ..siblingSeparation = 15
            ..levelSeparation = 15
            ..subtreeSeparation = 15
            ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM,
          TreeEdgeRenderer(BuchheimWalkerConfiguration()),
        ),
        paint: Paint()
          ..color = theme.colorScheme.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
        builder: (Node node) {
          final nodeId = node.key!.value as String;
          final label = nodeLabels[nodeId] ?? 'Unknown';
          final isCurrentNode = nodeId == controller.currentNodeId.value;
          final chatNode =
              controller.nodes.firstWhereOrNull((n) => n.id == nodeId);

          return GestureDetector(
            onTap: () {
              controller.currentNodeId.value = nodeId;
              Get.back(); // Close drawer
              Get.snackbar(
                'Navigation',
                'Switched to: ${label}',
                duration: const Duration(seconds: 2),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCurrentNode
                    ? theme.colorScheme.primary
                    : (chatNode?.isUser ?? false)
                        ? theme.colorScheme.surface
                        : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline,
                  width: isCurrentNode ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (chatNode?.isUser ?? false)
                        ? Icons.person
                        : Icons.smart_toy,
                    size: 16,
                    color: isCurrentNode
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isCurrentNode ? FontWeight.bold : FontWeight.normal,
                      color: isCurrentNode
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
