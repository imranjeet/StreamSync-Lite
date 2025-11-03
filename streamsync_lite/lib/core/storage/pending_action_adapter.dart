import 'dart:convert';
import 'package:hive/hive.dart';
import '../../shared/models/pending_action.dart';

class PendingActionAdapter extends TypeAdapter<PendingAction> {
  @override
  final int typeId = 2;

  @override
  PendingAction read(BinaryReader reader) {
    final id = reader.readString();
    final actionType = reader.readString();
    final payloadStr = reader.readString();
    final idempotencyKeyStr = reader.readByte() == 1 ? reader.readString() : null;
    final updatedAtStr = reader.readString();
    
    return PendingAction(
      id: id,
      actionType: actionType,
      payload: Map<String, dynamic>.from(json.decode(payloadStr)),
      idempotencyKey: idempotencyKeyStr,
      updatedAt: DateTime.parse(updatedAtStr),
    );
  }

  @override
  void write(BinaryWriter writer, PendingAction obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.actionType);
    writer.writeString(json.encode(obj.payload));
    if (obj.idempotencyKey == null) {
      writer.writeByte(0);
    } else {
      writer.writeByte(1);
      writer.writeString(obj.idempotencyKey!);
    }
    writer.writeString(obj.updatedAt.toUtc().toIso8601String());
  }
}

