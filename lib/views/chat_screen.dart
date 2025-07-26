import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/conversation_drawer.dart';

class ChatScreen extends StatelessWidget {
  final ChatController controller = Get.find();

  ChatScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat MVP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.offNamed('/setup'),
          ),
        ],
      ),
      drawer: ConversationDrawer(),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: Obx(() {
              final conversationPath = controller.getCurrentConversationPath();
              
              if (conversationPath.isEmpty) {
                return const Center(
                  child: Text('Start a conversation...'),
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: conversationPath.length,
                itemBuilder: (context, index) {
                  final node = conversationPath[index];
                  return ChatBubble(
                    node: node,
                    onLongPress: () => controller.createBranch(node.id),
                  );
                },
              );
            }),
          ),

          // Loading Indicator
          Obx(() => controller.isLoading.value
              ? const LinearProgressIndicator()
              : const SizedBox.shrink()),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller.messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: controller.sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () => controller.sendMessage(
                    controller.messageController.text,
                  ),
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}