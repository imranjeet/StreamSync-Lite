import 'package:hive/hive.dart';
import '../../shared/models/progress.dart';

class ProgressAdapter extends TypeAdapter<Progress> {
  @override
  final int typeId = 3;

  @override
  Progress read(BinaryReader reader) {
    final userId = reader.readString();
    final videoId = reader.readString();
    final positionSeconds = reader.readInt();
    final completedPercent = reader.readDouble();
    final synced = reader.readBool();
    final updatedAtStr = reader.readString();

    return Progress(
      userId: userId,
      videoId: videoId,
      positionSeconds: positionSeconds,
      completedPercent: completedPercent,
      synced: synced,
      updatedAt: DateTime.parse(updatedAtStr),
    );
  }

  @override
  void write(BinaryWriter writer, Progress obj) {
    writer.writeString(obj.userId);
    writer.writeString(obj.videoId);
    writer.writeInt(obj.positionSeconds);
    writer.writeDouble(obj.completedPercent);
    writer.writeBool(obj.synced);
    writer.writeString(obj.updatedAt.toUtc().toIso8601String());
  }
}

