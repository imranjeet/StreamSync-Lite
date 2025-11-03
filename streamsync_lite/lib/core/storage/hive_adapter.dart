import 'dart:convert';
import 'package:hive/hive.dart';
import '../../shared/models/notification.dart';

class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 0;

  @override
  AppNotification read(BinaryReader reader) {
    final id = reader.readString();
    final userId = reader.readString();
    final title = reader.readString();
    final body = reader.readString();
    final isRead = reader.readBool();
    final isDeleted = reader.readBool();
    final linkedContentStr = reader.readByte() == 1 ? reader.readString() : null;
    final metadataStr = reader.readByte() == 1 ? reader.readString() : null;
    final createdAt = DateTime.parse(reader.readString());
    final updatedAtStr = reader.readByte() == 1 ? reader.readString() : null;
    
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      body: body,
      isRead: isRead,
      isDeleted: isDeleted,
      linkedContent: linkedContentStr,
      metadata: metadataStr != null ? Map<String, dynamic>.from(json.decode(metadataStr)) : null,
      createdAt: createdAt,
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : null,
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.userId);
    writer.writeString(obj.title);
    writer.writeString(obj.body);
    writer.writeBool(obj.isRead);
    writer.writeBool(obj.isDeleted);
    if (obj.linkedContent == null) {
      writer.writeByte(0);
    } else {
      writer.writeByte(1);
      writer.writeString(obj.linkedContent!);
    }
    if (obj.metadata == null) {
      writer.writeByte(0);
    } else {
      writer.writeByte(1);
      writer.writeString(json.encode(obj.metadata));
    }
    writer.writeString(obj.createdAt.toIso8601String());
    if (obj.updatedAt == null) {
      writer.writeByte(0);
    } else {
      writer.writeByte(1);
      writer.writeString(obj.updatedAt!.toIso8601String());
    }
  }
}

