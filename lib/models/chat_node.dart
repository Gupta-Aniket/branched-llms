import 'package:hive/hive.dart';

part 'chat_node.g.dart';

@HiveType(typeId: 0)
class ChatNode extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String content;

  @HiveField(2)
  String summary;

  @HiveField(3)
  String? parentId;

  @HiveField(4)
  List<String> children;

  @HiveField(5)
  bool isUser;

  @HiveField(6)
  DateTime timestamp;

  ChatNode({
    required this.id,
    required this.content,
    this.summary = '',
    this.parentId,
    List<String>? children,
    required this.isUser,
    DateTime? timestamp,
  })  : children = children ?? [],
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'summary': summary,
        'parentId': parentId,
        'children': children,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatNode.fromJson(Map<String, dynamic> json) => ChatNode(
        id: json['id'],
        content: json['content'],
        summary: json['summary'] ?? '',
        parentId: json['parentId'],
        children: List<String>.from(json['children'] ?? []),
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}