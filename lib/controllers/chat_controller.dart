import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/chat_node.dart';
import '../services/api_service.dart';

class ChatController extends GetxController {
  final RxList<ChatNode> nodes = <ChatNode>[].obs;
  final RxString currentNodeId = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString apiKey = ''.obs;
  final RxString provider = ''.obs;

  late Box<ChatNode> _nodeBox;
  late SharedPreferences _prefs;
  late ApiService _apiService;

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    try {
      _nodeBox = await Hive.openBox<ChatNode>('nodes');
      _prefs = await SharedPreferences.getInstance();

      apiKey.value = _prefs.getString('api_key') ?? '';
      provider.value = _prefs.getString('provider') ?? '';

      _apiService = ApiService();

      _loadNodes();

      if (nodes.isEmpty) {
        await _createInitialNode();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize storage: $e');
    }
  }

  void _loadNodes() {
    final storedNodes = _nodeBox.values.toList();
    nodes.assignAll(storedNodes);

    if (nodes.isNotEmpty) {
      currentNodeId.value = nodes.last.id;
    }
  }

  Future<void> _createInitialNode() async {
    final initialNode = ChatNode(
      id: _generateId(),
      content: 'Welcome! Start a conversation...',
      isUser: false,
    );

    await _saveNode(initialNode);
    currentNodeId.value = initialNode.id;
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  Future<void> _saveNode(ChatNode node) async {
    await _nodeBox.put(node.id, node);
    if (!nodes.any((n) => n.id == node.id)) {
      nodes.add(node);
    }
  }

  /// ✅ Build context chain using FULL content, no summaries
  List<Map<String, String>> getCurrentContextAsChat() {
    final current = nodes.firstWhereOrNull((n) => n.id == currentNodeId.value);
    if (current == null) return [];

    List<Map<String, String>> chat = [];
    ChatNode? node = current;
    while (node != null) {
      chat.insert(0, {
        'role': node.isUser ? 'user' : 'assistant',
        'content': node.content, // 🔥 Always use full content
      });
      node = node.parentId != null
          ? nodes.firstWhereOrNull((n) => n.id == node!.parentId)
          : null;
    }
    return chat;
  }

  Future<void> saveApiConfiguration(String key, String selectedProvider) async {
    apiKey.value = key;
    provider.value = selectedProvider;

    await _prefs.setString('api_key', key);
    await _prefs.setString('provider', selectedProvider);

    Get.snackbar(
      'Success',
      'Configuration saved!',
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
    );
  }

  bool get isConfigured => apiKey.value.isNotEmpty && provider.value.isNotEmpty;

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || !isConfigured) return;

    isLoading.value = true;

    try {
      final userNode = ChatNode(
        id: _generateId(),
        content: message.trim(),
        isUser: true,
        parentId: currentNodeId.value.isEmpty ? null : currentNodeId.value,
      );

      if (currentNodeId.value.isNotEmpty) {
        final parent = nodes.firstWhere((n) => n.id == currentNodeId.value);
        parent.children.add(userNode.id);
        await _saveNode(parent);
      }

      await _saveNode(userNode);
      currentNodeId.value = userNode.id;

      final context = getCurrentContextAsChat();
      final response = await _apiService.sendMessage(
        context,
        provider.value,
        apiKey.value,
      );

      final aiNode = ChatNode(
        id: _generateId(),
        content: response,
        isUser: false,
        parentId: userNode.id,
      );

      userNode.children.add(aiNode.id);
      await _saveNode(userNode);
      await _saveNode(aiNode);

      currentNodeId.value = aiNode.id;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      log(e.toString());
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      messageController.clear();
    }
  }

  /// ✅ Branch creation still works with full content
  Future<void> createBranch(String nodeId) async {
    try {
      final sourceNode = nodes.firstWhere((n) => n.id == nodeId);

      final branchNode = ChatNode(
        id: _generateId(),
        content: sourceNode.content,
        isUser: sourceNode.isUser,
        parentId: sourceNode.parentId,
      );

      if (sourceNode.parentId != null) {
        final parent = nodes.firstWhere((n) => n.id == sourceNode.parentId);
        parent.children.add(branchNode.id);
        await _saveNode(parent);
      }

      await _saveNode(branchNode);
      currentNodeId.value = branchNode.id;

      Get.snackbar(
        'Branch Created',
        'New conversation branch started',
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to create branch: $e');
    }
  }

  List<ChatNode> getCurrentConversationPath() {
    if (currentNodeId.value.isEmpty) return [];

    List<ChatNode> path = [];
    String? nodeId = currentNodeId.value;

    while (nodeId != null) {
      try {
        final node = nodes.firstWhere((n) => n.id == nodeId);
        path.insert(0, node);
        nodeId = node.parentId;
      } catch (e) {
        break;
      }
    }

    return path;
  }

  Map<String, dynamic> getGraphData() {
    Map<String, List<String>> adjacencyList = {};
    Map<String, String> nodeLabels = {};

    for (final node in nodes) {
      nodeLabels[node.id] = node.content.length > 20
          ? '${node.content.substring(0, 20)}...'
          : node.content;

      adjacencyList[node.id] = node.children;
    }

    return {
      'adjacencyList': adjacencyList,
      'nodeLabels': nodeLabels,
    };
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
