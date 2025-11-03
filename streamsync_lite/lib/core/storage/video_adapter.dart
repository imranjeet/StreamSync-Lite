import 'package:hive/hive.dart';
import '../../shared/models/video.dart';

class VideoAdapter extends TypeAdapter<Video> {
  @override
  final int typeId = 1;

  @override
  Video read(BinaryReader reader) {
    final videoId = reader.readString();
    final title = reader.readString();
    final descriptionStr = reader.readByte() == 1 ? reader.readString() : null;
    final thumbnailUrl = reader.readString();
    final durationBytes = reader.readByte();
    final int? durationSeconds = durationBytes == 0 ? null : reader.readInt();
    final publishedAtStr = reader.readByte() == 1 ? reader.readString() : null;
    final channelIdStr = reader.readByte() == 1 ? reader.readString() : null;
    final channelNameStr = reader.readByte() == 1 ? reader.readString() : null;
    
    return Video(
      videoId: videoId,
      title: title,
      description: descriptionStr,
      thumbnailUrl: thumbnailUrl,
      durationSeconds: durationSeconds,
      publishedAt: publishedAtStr != null ? DateTime.parse(publishedAtStr) : null,
      channelId: channelIdStr,
      channelName: channelNameStr,
    );
  }

  @override
  void write(BinaryWriter writer, Video obj) {
    writer.writeString(obj.videoId);
    writer.writeString(obj.title);
    if (obj.description == null) {
      writer.writeByte(0);
    } else {
      writer.writeByte(1);
      writer.writeString(obj.description!);
    }
    writer.writeString(obj.thumbnailUrl);
    if (obj.durationSeconds == null) {
      writer.writeByte(0);
    } else {
      writer.writeByte(1);
      writer.writeInt(obj.durationSeconds!);
    }
    if (obj.publishedAt == null) {
      writer.writeByte(0);
    } else {
      writer.writeByte(1);
      writer.writeString(obj.publishedAt!.toIso8601String());
    }
    if (obj.channelId == null) {
      writer.writeByte(0);
    } else {
      writer.writeByte(1);
      writer.writeString(obj.channelId!);
    }
    if (obj.channelName == null) {
      writer.writeByte(0);
    } else {
      writer.writeByte(1);
      writer.writeString(obj.channelName!);
    }
  }
}

