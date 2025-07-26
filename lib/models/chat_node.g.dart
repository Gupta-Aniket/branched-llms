// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatNodeAdapter extends TypeAdapter<ChatNode> {
  @override
  final int typeId = 0;

  @override
  ChatNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatNode(
      id: fields[0] as String,
      content: fields[1] as String,
      summary: fields[2] as String,
      parentId: fields[3] as String?,
      children: (fields[4] as List?)?.cast<String>(),
      isUser: fields[5] as bool,
      timestamp: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatNode obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.summary)
      ..writeByte(3)
      ..write(obj.parentId)
      ..writeByte(4)
      ..write(obj.children)
      ..writeByte(5)
      ..write(obj.isUser)
      ..writeByte(6)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}